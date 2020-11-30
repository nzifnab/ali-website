# My nephew wanted me to make a number-guessing game so I shimmied it into a hidden url on the site. Sue me.
class GuessController < ApplicationController
  def show
    @num = (rand*10+1).to_i
  end
  def create
    @num = params[:answer]
    if params[:num].to_i < params[:answer].to_i
      flash.now[:success] = "HIGHER"
    elsif params[:num].to_i > params[:answer].to_i
      flash.now[:success] = "LOWER"
    elsif params[:num].to_i == params[:answer].to_i
      flash.now[:success] = "CORRECT"

        @num = (rand*10+1).to_i
    end
    render action: 'show'
  end
end
