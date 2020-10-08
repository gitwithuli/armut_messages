![Simple Messaging System as Armut Messages](https://res.cloudinary.com/dbjtqhjxi/image/upload/v1602158392/Kazam_screenshot_00053_nspf5z.png)

### Generate migration for conversations
```bash
$ rails g migration createConversations
```

```ruby
class CreateConversations < ActiveRecord::Migration
 def change
  create_table :conversations do |t|
   t.integer :sender_id
   t.integer :recipient_id

   t.timestamps
  end
 end
end
```

### Generate migration for messages

```bash
$ rails g migration createMessages
```

```ruby
class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
    t.text :body
    t.references :conversation, index: true
    t.references :user, index: true

    t.timestamps
    end
  end
end
```

### Generate Conversation Model

```bash
$ rails g model Conversation --skip-migration
```

### Update the Conversation model

```ruby
# app/models/conversation.rb

class Conversation < ApplicationRecord
  belongs_to :sender, foreign_key: :sender_id, class_name: "User"
  belongs_to :recipient, foreign_key: :recipient_id, class_name: "User"

  has_many :messages

  validates_uniqueness_of :sender_id, scope: :recipient_id

  # This scope validation takes the sender_id and recipient_id for the conversation and checks whether a conversation exists between the two ids because we only want two users to have one conversation.

  scope :between, -> (sender_id, recipient_id) do
    where("(conversations.sender_id = ? AND conversations.recipient_id = ?) OR (conversations.sender_id = ? AND conversations.recipient_id = ?)", sender_id, recipient_id, recipient_id, sender_id)
  end
end
```

### Message model

```bash
$ rails g model Message --skip-migration
```

```ruby
# app/models/message.rb
class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :user
  validates_presence_of :body, :conversation_id, :user_id

  def message_time
    created_at.strftime("%d/%m/%y at %k:%M")
  end
end
```

### Block Model

```ruby
rails g model Block
```

```ruby
# db/migrations/create_blocks.rb
class CreateBlocks < ActiveRecord::Migration[6.0]
  def change
    create_table :blocks do |t|
      t.integer 'blocker_id', null: false
      t.integer 'blockee_id', null: false

      t.timestamps null: false
    end

    add_index :blocks, :blocker_id
    add_index :blocks, :blockee_id
    add_index :blocks, [:blocker_id, :blockee_id], unique: true
  end
end
```
Running rails:db and updating User and Block models :

```ruby
# app/models/block.rb
class Block < ApplicationRecord
  belongs_to :blocker, foreign_key: 'blocker_id', class_name: 'User'
  belongs_to :blockee, foreign_key: 'blockee_id', class_name: 'User'
end
```
Both blocker and blockee are instances of User. There are two ways that Users can be connected to Block: They can have many blockee_relationships, i.e., they are being blocked, or they have many blocker_relationships, i.e., they are blocking other users.

Because we are not using the name of a model for these relationships, we need to let Rails know how to build them by specifying the foreign_key and the class_name of the model.

We’ll also add some custom methods to the User model to have a simpler way of blocking and unblocking users and to check if a user is blocking another:


```ruby
# app/models/user.rb
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :blocker_relationships, foreign_key: :blocker_id, class_name: 'Block'
  has_many :blocker, through: :blocker_relationships, source: :blocker

  has_many :blockee_relationships, foreign_key: :blockee_id, class_name: 'Block'
  has_many :blockee, through: :blockee_relationships, source: :blockee


  def block(user_id)
    blocker_relationships.create(blockee_id: user_id)
  end

  def unblock(user_id)
    blocker_relationships.find_by(blockee_id: user_id).destroy
  end

  def is_blocked?(user_id)
    relationship = Block.find_by(blocker_id: id, blockee_id: user_id)
    return true if relationship
  end

end

```

### Conversations Controller

```ruby
# app/controllers/conversations_controller.rb
class ConversationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @users = User.all
    @conversations = Conversation.all
  end

  def create
    if current_user.is_blocked?(current_user.id == params[:recipient_id] ? params[:sender_id] : params[:recipient_id])
      redirect_to root_path, alert: "This user is blocked."
    else
      if Conversation.between(params[:sender_id], params[:recipient_id]).present?
        @conversation = Conversation.between(params[:sender_id], params[:recipient_id]).first
      else
        @conversation = Conversation.create!(conversation_params)
      end
      redirect_to conversation_messages_path(@conversation)
    end
  end


  private
    def conversation_params
      params.permit(:sender_id, :recipient_id)
    end

end


```

### Message Controller

```ruby
# app/controllers/messages_controller.rb
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
```
### Update the routes

```ruby
Rails.application.routes.draw do
  devise_for :users
  root to: 'pages#home'

  resources :conversations do
    resources :messages
  end

  resources :users, only: [:index] do
    member do
      post :block
      post :unblock
    end
  end
end
```
### Messages index view
```html
<!-- app/views/messages/index.html.erb -->
<div class="d-flex container justify-content-center align-items-center">
  <div class="row mt-4">
    <div class="col-12">
      <h1 class="title is-4">Conversation with <%= @conversation.recipient.email %></h1>

      <section id="messages" class="mt-4">
        <% @messages.each do |message| %>
        <% if message.body %>
        <% user = User.find(message.user_id) %>
        <article class="message <%= 'right' if user == current_user %>">
          <div class="content-container">
            <div class="inline-block"><strong><%= user.email %></strong> <%= message.message_time %></div>
            <div class="message-body <%= 'me' if user == current_user %>"><%= message.body %></div>
          </div>
        </article>
        <% end %>
        <% end %>
      </section>

      <%= form_for [@conversation, @message] do |f| %>
      <%= f.text_area :body, class: "textarea w-100 mt-4", placeholder: "Write your message here..." %>
      <%= f.text_field :user_id, value: current_user.id, type: "hidden"  %>
        <%= f.submit "Send message", class: "btn btn-primary btn-block" %>
      <% end %>
      <%= link_to "Back to all conversations", conversations_path, class: "btn btn-danger mt-5 mb-5" %>
      <%= link_to "Block User", block_user_path(current_user.id == @conversation.recipient_id ? @conversation.sender_id : @conversation.recipient_id), method: :post, class: "btn btn-danger mt-5 mb-5", data: {confirm:"You're blocking this user. Are you sure?"} %>
    </div>
  </div>
</div>
```

### Conversations index view

```html
<div class="container">
  <div class="row mt-5">
    <div class="col-6 text-center">
    <h3>All Users</h3>
    <% @users.each do |user| %>
      <% if user.id != current_user.id %>
       <%= link_to "Message #{user.email}", conversations_path(sender_id: current_user.id, recipient_id: user.id), method: "post", class: "btn btn-primary btn-block mb-3" %>
      <% end %>
    <% end %>
    </div>

  <div class="col-6 text-center">
      <h3>Conversations</h3>
      <% @conversations.each do |conversation| %>
        <% if conversation.sender_id == current_user.id || conversation.recipient_id == current_user.id %>
          <% if conversation.sender_id == current_user.id %>
            <% recipient = User.find(conversation.recipient_id) %>
          <% else %>
            <% recipient = User.find(conversation.sender_id) %>
          <% end %>
          <% unless current_user.id == recipient %>
                <p><%= link_to recipient.email, conversation_messages_path(conversation), class: "btn btn-danger btn-block" %></p>
          <% end %>
        <% end %>
      <% end %>
    </div>
  </div>
</div>
```
### Start with Docker-Compose
  docker-compose up
