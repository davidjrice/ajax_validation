module ActionController
  # Macros are class-level calls that add pre-defined actions to the controller based on the parameters passed in.
  # Currently, they're used to bridge the JavaScript macros, like autocompletion and in-place editing, with the controller
  # backing.
  module Macros
    module AjaxValidation #:nodoc:
      def self.included(base) #:nodoc:
        base.extend(InstanceMethods)
        base.extend(ClassMethods)
      end
      # Example:
      #
      #   # Controller
      #   class BlogController < ApplicationController
      #     ajax_validation_for :post
      #   end
      #   
      #   # Routes
      #   map.resources :posts, :collection => [:validate]
      #
      #   # View
      #
      module InstanceMethods
        def javascript_for_ajax_update(object,attribute,replacement="")
          error = {:rgb => 'rgb(255, 99, 99)', :hex => '#FF6363' }
          valid = {:rgb => 'rgb(99, 255, 104)', :hex => '#63FF68'}
          if replacement == ""
            color = valid
            alt = error
            effect = "Fade"
          else
            color = error
            alt = valid
            effect = "Appear"
          end
          js = "
          var current = $('#{object.to_s}_#{attribute}');
          if(current.getStyle('background-color') == '#{color[:rgb]}'){
            //cock
          } else if(current.getStyle('background-color') == 'rgb(255, 255, 255)'){
            new Effect.Highlight(\"#{object.to_s}_#{attribute}\",{startcolor:'#FFFFFF', endcolor:'#{color[:hex]}', restorecolor:'#{color[:hex]}'});
          } else {
            new Effect.Highlight(\"#{object.to_s}_#{attribute}\",{startcolor:'#{alt[:hex]}', endcolor:'#{color[:hex]}', restorecolor:'#{color[:hex]}'});              
          }            
          var current_validation = $('#{object.to_s}_#{attribute}_validation');
          if(current_validation.getStyle('display') == 'none'){
          } else{
            new Effect.#{effect}(\"#{object.to_s}_#{attribute}_validation\",{});
          }"
          return js
        end
      end
      module ClassMethods
        def ajax_validation_for(object, options = {})

          define_method("validate") do
            
            @valid_keys = options[:valid_keys] || object.to_s.camelize.constantize.column_names
            parameters = params[object]
            @attributes = parameters #.delete_if { |key,value| !valid_keys.include?(key)}    
            return if @attributes.empty?
            @object = object.to_s.camelize.constantize.new @attributes
            @object.valid?
            @kontroller = object.to_s.pluralize + "_controller"
            @kontroller = @kontroller.camelize.constantize
            
            #respond_to do |type|
              #type.rjs do
                render :update do |page| 
                  @attributes.delete_if { |key,value| !@valid_keys.include?(key)}
                  @attributes.each do |attribute,value|
                    if @object.errors.on(attribute) and !value.nil? and !value.blank?
                      output = "<ul>\n"
                      @object.errors.each do |field,error|
                        if field.to_sym == attribute.to_sym
                            output = output + "<li>#{field.humanize} #{error}</li>\n"
                        end
                      end
                      
                      page.visual_effect :appear, "#{object.to_s}_#{attribute}_validation"
                      output = output + "</ul>\n"
                      page.replace_html "#{object.to_s}_#{attribute}_validation", output
                      
                      page << @kontroller.javascript_for_ajax_update(object,attribute,output)

                    elsif !value.nil? and !value.blank?
                      js = @kontroller.javascript_for_ajax_update(object,attribute,"")
                      page << js
                      page.replace_html "#{object.to_s}_#{attribute}_validation", ""
                    #end
                  #end
                end
              end
            end
          end
        end
      end
    end
  end
end