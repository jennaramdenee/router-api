require 'router_reloader'

class RoutesController < ApplicationController
  before_filter :ensure_route_keys, :only => [:update]

  def show
    @route = Route.find_by_incoming_path_and_route_type!(params[:incoming_path], params[:route_type])
    render :json => @route
  end

  def update
    route_details = params[:route]
    @route = Route.find_or_initialize_by_incoming_path_and_route_type(route_details.delete(:incoming_path), route_details.delete(:route_type))
    status_code = @route.new_record? ? 201 : 200
    if @route.update_attributes(route_details)
      render :json => @route, :status => status_code
    else
      render :json => @route, :status => 400
    end
  end

  def destroy
    @route = Route.find_by_incoming_path_and_route_type!(params[:incoming_path], params[:route_type])
    if params[:hard_delete] == "true"
      @route.destroy
    else
      @route.soft_delete
    end
    render :json => @route
  end

  def commit
    if RouterReloader.reload
      render :text => "Router reloaded"
    else
      render :text => "Failed to reload all routers", :status => 500
    end
  end

  private

  def ensure_route_keys
    unless params[:route].respond_to?(:has_key?) and params[:route].has_key?(:incoming_path) and params[:route].has_key?(:route_type)
      render :json => {"error" => "Required route keys (incoming_path and route_type) missing"}, :status => 400
    end
  end
end
