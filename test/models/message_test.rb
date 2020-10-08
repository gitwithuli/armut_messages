require 'test_helper'

class MessageTest < ActiveSupport::TestCase
  test "should not save message without body" do
    message = Message.new
    assert !message.save
  end
end
