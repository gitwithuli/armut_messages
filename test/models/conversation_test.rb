require 'test_helper'

class ConversationTest < ActiveSupport::TestCase
  test "should not create a conversation without sender_id" do
    conversation = Conversation.new
    assert !conversation.save
  end
end
