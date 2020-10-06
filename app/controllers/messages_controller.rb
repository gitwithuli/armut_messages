class MessagesController < ApplicationController
  before_action :find_conversation

  def index
    if current_user.is_blocked?(current_user.id == @conversation.recipient_id ? @conversation.sender_id : @conversation.recipient_id)
      redirect_to root_path, alert: "This user is blocked."
    else
    @messages = @conversation.messages
    @message = @conversation.messages.new
    end
  end

  def create
    @message = @conversation.messages.build(message_params)
    @message.user = current_user
    if @message.save
      redirect_to conversation_messages_path(@conversation)
    end
  end

  def new
    @message = @conversation.messages.new
  end



  private

    def message_params
      params.require(:message).permit(:body)
    end

    def find_conversation
      @conversation = Conversation.find(params[:conversation_id])
    end
end
