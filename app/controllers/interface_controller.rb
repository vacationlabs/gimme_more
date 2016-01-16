class InterfaceController < ApplicationController
  
  def get
    @articles = Recommendation.get_recommendations(params[:url])
    render :json => @articles
  end

end
