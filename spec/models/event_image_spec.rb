# frozen_string_literal: true

require "rails_helper"

RSpec.describe Event, "image" do
  let(:event) { create(:event) }
  let(:poster_url) { "https://images.example.com/poster.jpg" }
  let(:jpeg) { file_fixture("good-cat-picture.jpg").read }

  def stub_image(url, body: jpeg, content_type: "image/jpeg", status: 200)
    stub_request(:get, url).to_return(status:, body:, headers: { "Content-Type" => content_type })
  end

  it "downloads and stores the image when the source gives a URL" do
    request = stub_image(poster_url)

    event.update!(image_source_url: poster_url)

    expect(request).to have_been_requested.once
    expect(event.reload.image).to be_present
    expect(File.binread(event.image.path)).to start_with("\xFF\xD8".b)
    expect(event.image.url).to match(%r{\A/uploads/event/image/#{event.id}/\h{16}\.jpg\z})
    expect(event.image_source_url).to eq(poster_url)
  end

  it "fetches nothing when the source's URL is unchanged" do
    request = stub_image(poster_url)
    event.update!(image_source_url: poster_url)

    described_class.find(event.id).update!(image_source_url: poster_url)

    expect(request).to have_been_requested.once
  end

  it "replaces the image when the source's URL changes" do
    stub_image(poster_url)
    stub_image("https://images.example.com/new.png", body: file_fixture("test-image.png").read, content_type: "image/png")
    event.update!(image_source_url: poster_url)
    old_path = event.image.path

    event.update!(image_source_url: "https://images.example.com/new.png")

    expect(event.reload.image.url).to end_with(".png")
    expect(File.exist?(old_path)).to be(false)
  end

  it "removes the image when the source stops giving one" do
    stub_image(poster_url)
    event.update!(image_source_url: poster_url)
    path = event.image.path

    event.update!(image_source_url: nil)

    expect(event.reload.image).to be_blank
    expect(File.exist?(path)).to be(false)
  end

  it "saves the event without an image, to try again next import, when the download fails" do
    stub_image(poster_url, status: 404, body: "")

    expect(event.update(image_source_url: poster_url)).to be(true)
    expect(event.reload.image).to be_blank
    expect(event.image_source_url).to be_nil
  end

  it "saves the event without an image, and doesn't try again, when the source's URL isn't an image" do
    request = stub_image(poster_url, body: "<html></html>", content_type: "text/html")

    expect(event.update(image_source_url: poster_url)).to be(true)
    described_class.find(event.id).update!(image_source_url: poster_url)

    expect(event.reload.image).to be_blank
    expect(request).to have_been_requested.once
  end

  it "stores no image when the source sends an empty file" do
    stub_image(poster_url, body: "")

    event.update!(image_source_url: poster_url)

    expect(event.reload.image).to be_blank
  end

  it "drops the old image when the source's new one can't be downloaded" do
    stub_image(poster_url)
    stub_image("https://images.example.com/gone.jpg", status: 404, body: "")
    event.update!(image_source_url: poster_url)
    old_path = event.image.path

    event.update!(image_source_url: "https://images.example.com/gone.jpg")

    expect(event.reload.image).to be_blank
    expect(File.exist?(old_path)).to be(false)
  end

  it "saves the event without an image, to try again next import, when caching the download fails" do
    stub_image(poster_url)
    allow_any_instance_of(EventImageUploader).to receive(:cache!).and_raise(Errno::EACCES, "uploads/tmp") # rubocop:disable RSpec/AnyInstance

    expect(event.update(image_source_url: poster_url)).to be(true)
    expect(event.reload).to have_attributes(image_source_url: nil)
    expect(event.image).to be_blank
  end

  it "keeps the event, without an image, when writing the file fails after the download" do
    stub_image(poster_url)
    allow_any_instance_of(EventImageUploader).to receive(:store!).and_raise(Errno::ENOSPC) # rubocop:disable RSpec/AnyInstance

    expect(event.update(image_source_url: poster_url)).to be(true)
    expect(event.reload).to have_attributes(image_source_url: nil, summary: event.summary)
    expect(event.read_attribute(:image)).to be_nil
  end

  it "deletes the image with the event" do
    stub_image(poster_url)
    event.update!(image_source_url: poster_url)
    path = event.image.path

    event.destroy!

    expect(File.exist?(path)).to be(false)
  end
end
