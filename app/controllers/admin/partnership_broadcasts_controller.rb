# frozen_string_literal: true

module Admin
  # Partnership-admin broadcasts (#3256 phase 4): compose with a recipient
  # preview, confirm, then one delivery job per opted-in recipient. The
  # index is the sent-broadcasts log.
  class PartnershipBroadcastsController < Admin::ApplicationController
    DELIVERY_STAGGER = 5.seconds

    before_action :set_partnership

    def index
      authorize PartnershipBroadcast.new(partnership: @partnership)
      render Views::Admin::PartnershipBroadcasts::Index.new(
        partnership: @partnership,
        broadcasts: policy_scope(PartnershipBroadcast)
                    .where(partnership: @partnership)
                    .recent_first
                    .includes(:sender)
      )
    end

    def new
      @broadcast = PartnershipBroadcast.new(partnership: @partnership)
      authorize @broadcast
      render Views::Admin::PartnershipBroadcasts::New.new(broadcast: @broadcast, recipients: recipients)
    end

    def create
      @broadcast = PartnershipBroadcast.new(partnership: @partnership,
                                            sender: current_user,
                                            recipient_count: recipients.eligible.size,
                                            excluded_count: recipients.excluded_count,
                                            **broadcast_params)
      authorize @broadcast

      if @broadcast.invalid?
        render Views::Admin::PartnershipBroadcasts::New.new(broadcast: @broadcast, recipients: recipients),
               status: :unprocessable_content
      elsif params[:confirmed] != 'true'
        # Confirm step: nothing is saved or sent yet
        render Views::Admin::PartnershipBroadcasts::Confirm.new(broadcast: @broadcast, recipients: recipients)
      else
        @broadcast.save!
        enqueue_deliveries
        flash[:success] = t('.sent', count: @broadcast.recipient_count)
        redirect_to admin_partnership_broadcasts_path(@partnership)
      end
    end

    private

    def set_partnership
      @partnership = Partnership.friendly.find(params[:partnership_id])
    end

    def recipients
      @recipients ||= BroadcastRecipientsQuery.new(partnership: @partnership)
    end

    def broadcast_params
      params.require(:partnership_broadcast).permit(:subject, :body)
    end

    def enqueue_deliveries
      recipients.eligible.each_with_index do |user, index|
        PartnershipBroadcastDeliveryJob.set(wait: index * DELIVERY_STAGGER).perform_later(user, @broadcast)
      end
    end
  end
end
