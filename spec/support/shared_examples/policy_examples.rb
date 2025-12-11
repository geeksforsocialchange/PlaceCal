# frozen_string_literal: true

# Shared examples for Pundit policy testing
RSpec.shared_examples 'allows access' do |action|
  it "allows #{action}" do
    expect(policy.send("#{action}?")).to be true
  end
end

RSpec.shared_examples 'denies access' do |action|
  it "denies #{action}" do
    expect(policy.send("#{action}?")).to be false
  end
end

RSpec.shared_examples 'allows all CRUD actions' do
  %i[index show new create edit update destroy].each do |action|
    include_examples 'allows access', action
  end
end

RSpec.shared_examples 'denies all CRUD actions' do
  %i[index show new create edit update destroy].each do |action|
    include_examples 'denies access', action
  end
end

RSpec.shared_examples 'allows read-only actions' do
  %i[index show].each do |action|
    include_examples 'allows access', action
  end

  %i[new create edit update destroy].each do |action|
    include_examples 'denies access', action
  end
end

# Helper methods for policy specs
module PolicySpecHelpers
  def permits(user, record, action)
    policy_class = "#{record.class}Policy".constantize
    policy_class.new(user, record).send("#{action}?")
  end

  def permitted_records(user, klass)
    scope_class = "#{klass}Policy::Scope".constantize
    scope_class.new(user, klass).resolve.to_a
  end
end

RSpec.configure do |config|
  config.include PolicySpecHelpers, type: :policy
end
