class UsersController < ApplicationController
  before_action :set_user, only: [:block, :unblock]

  def index
    @users = User.where.not(id: current_user.id)
  end

  def block
    if current_user.block(@user.id)
       respond_to do |format|
         format.html { redirect_to root_path }
         format.js
       end
    end
  end

  def unblock
    if current_user.unblock(@user.id)
      respond_to do |format|
        format.html { redirect_to root_path }
        format.js { render action: :block }
      end
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

end
