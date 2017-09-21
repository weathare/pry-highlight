Pry::Commands.create_command ">>" do
  description %(highlight intelligently formats and colorize the result)

  banner %(Usage: >> [-t <type>] <optional ruby code>)

  command_options shellwords: false

  def options(opt)
    opt.on :t, :type, %(Specify the type to be highlight), argument: true, as: Symbol
  end

  def process
    require "json"
    require "nokogiri"

    value = target.eval args.join(" ").sub(/\A *\z/, "_")
    type = opts[:type] ? opts[:type] : nil

    begin
      value = value.to_str
    rescue NoMethodError
      Pry.config.print.call(output, value) unless value.respond_to?(:to_str)
    end

    if type == :json || !type && value.start_with?("{") || value.start_with?("[")
      begin
        value = JSON.pretty_generate(JSON.parse(value))
        type = :json
      rescue Pry::RescuableException => e
        output.puts e.to_s
      end
    elsif type == :html || !type && value.start_with?("<html")
      begin
        value = Nokogiri::HTML(value).to_xhtml.lines.drop(1).join
        type = :html
      rescue Pry::RescuableException => e
        output.puts e.to_s
      end
    elsif type == :xml || !type && value.start_with?("<")
      begin
        value = Nokogiri::XML(value).to_xml
        type = :xml
      rescue Pry::RescuableException => e
        output.puts e.to_s
      end
    elsif !type
      if _pry_.respond_to?(:valid_expression?) && _pry_.valid_expression?(value) ||
         _pry_.respond_to?(:complete_expression?) && (begin _pry_.complete_expression?(value); true; rescue SyntaxError; false; end)
        type = :ruby
      end
    end

    if type
      output.puts CodeRay.scan(value, type).term
    elsif String === value
      output.puts value
    end
  end
end

Pry::Commands.alias_command "highlight", ">>"
