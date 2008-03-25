module Less
  module Captcha
    SALT = 'less_salt'
    SUFFIX = '_answer'
    PREFIX = 'captcha'

    module Validations
      def self.append_features(base)
        super
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Validates whether the value of the specified attribute passes the captcha challenge
        #
        #   class User < ActiveRecord::Base
        #     validates_captcha
        #   end
        #
        # Configuration options:
        # * <tt>message</tt> - A custom error message (default is: " did not match valid answer")
        # * <tt>on</tt> Specifies when this validation is active (default is :create, other options :save, :update)
        # * <tt>if</tt> - Specifies a method, proc or string to call to determine if the validation should
        #   occur (e.g. :if => :allow_validation, or :if => Proc.new { |user| user.signup_step > 2 }).  The
        #   method, proc or string should return or evaluate to a true or false value.
        def validates_captcha(options = {})
          attr_accessor PREFIX.to_sym, (PREFIX + SUFFIX).to_sym

          configuration = { :message => ' did not match valid answer', :on => :create }

          configuration.merge(options)

          validates_each(PREFIX, configuration) do |record, attr_name, value|
            record.errors.add(attr_name, configuration[:message]) unless record.send(PREFIX + SUFFIX) == Digest::SHA1.hexdigest(SALT + value)
          end
        end
      end
    end

    module InstanceMethods
      # Sets up the passing answer for the captcha challenge
      #
      #   setup_captcha
      #
      # options:
      # * <tt>answer</tt> - The passing answer for the captcha challenge
      def setup_captcha
        unless send(PREFIX) and send(PREFIX + SUFFIX)
          b = rand(10) + 1
          a = b + rand(10)
          op = ['+', '-'][rand(2)]
          question = "What is #{a} #{op} #{b}?"
          answer = a.send(op, b)
          
          send(PREFIX + '=', question.to_s)
          send(PREFIX + SUFFIX + '=', Digest::SHA1.hexdigest(SALT + answer.to_s))
        end
      end
    end

    module Helper
      # Use this helper to create a captcha challenge question
      #
      #   <%= captcha_field("entry") %>
      #
      # the following HTML will be generated. The hidden field contains an encrypted version of the answer
      #
      #   <input type="text" name="entry[captcha]" />
      #   <input type="hidden" name="entry[captcha_answer]" value="..." />
      #
      # You can use the +options+ argument to pass additional options to the text-field tag.
      def captcha_field(object, options={})
        if object.is_a?(String) or object.is_a?(Symbol)
          eval("@"+object.to_s).setup_captcha
        else
          object.setup_captcha
        end

        result = ActionView::Helpers::InstanceTag.new(object, PREFIX, self).to_input_field_tag("text", options)
        result << ActionView::Helpers::InstanceTag.new(object, PREFIX + SUFFIX, self).to_input_field_tag("hidden", {})
      end
      
      # Use this helper to display a captcha challenge question
      #
      #   <%= captcha_display %>
      #
      # the following HTML will be generated.
      #
      #   <span class='less_captcha_challenge'>...</span>
      #
      def captcha_display
        if object.is_a?(String) or object.is_a?(Symbol)
          eval("@"+object.to_s).setup_captcha
          captcha = eval("@"+object.to_s).send(PREFIX)
        else
          object.setup_captcha
          captcha = object.send(PREFIX)
        end
        
        "<span class='less_captcha_challenge'>#{captcha}</span>"
      end
    end
  end
end