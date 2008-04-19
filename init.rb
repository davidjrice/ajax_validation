# Include hook code here
require 'ajax_validation'
ActionController::Base.class_eval do
  include ActionController::Macros::AjaxValidation
end
ActionView::Base.send :include, AjaxValidationFormHelper