# frozen_string_literal: true

begin
  require "prism"
rescue LoadError
  warn "[calltally] prism not found. Install 'prism' gem or use Ruby 3.3+."
  raise
end

module Calltally
  class PrismVisitor < ::Prism::Visitor
    def initialize(config, pair_counts, method_counts, receiver_counts)
      super()

      @config          = config
      @pair_counts     = pair_counts
      @method_counts   = method_counts
      @receiver_counts = receiver_counts
      @class_stack     = []
    end

    def visit_class_node(node)
      class_name = extract_class_name(node.constant_path)
      @class_stack.push(class_name)

      super
    ensure
      @class_stack.pop
    end

    def visit_module_node(node)
      module_name = extract_class_name(node.constant_path)
      @class_stack.push(module_name)

      super
    ensure
      @class_stack.pop
    end

    def visit_call_node(node)
      meth  = node.name&.to_s
      rname = receiver_name(node.receiver)
      tally(rname, meth)

      super
    end

    def visit_block_argument_node(node)
      expr = node.expression

      if expr.is_a?(::Prism::SymbolNode)
        tally(nil, expr.value.to_s)
      end

      super
    end

    private

    def operator_like?(name)
      name = name.to_s
      !!(name =~ /\A(\[\]|\[\]=|[!~]|\*\*|===|==|!=|<=|>=|<<|>>|<|>|\+|-|\*|\/|%|\^|&|\|)\z/)
    end

    def tally(receiver_name, method_name)
      return if method_name.nil?
      return if @config["skip_operators"] && operator_like?(method_name)
      return if @config["methods"] && !@config["methods"].include?(method_name)

      # Filter by receiver type if specified
      if @config["receiver_types"] && !@config["receiver_types"].empty?
        return unless receiver_type_matches?(receiver_name, @config["receiver_types"])
      end

      if receiver_name.nil? && @config["include_nil_receiver"]
        receiver_name = current_context_with_hash
      end

      case @config["mode"].to_s.downcase.to_sym
      when :pairs
        if receiver_name
          return if @config["receivers"] && !@config["receivers"].include?(receiver_name)

          @pair_counts[[receiver_name, method_name]] += 1
          @receiver_counts[receiver_name] += 1
        else
          @method_counts[method_name] += 1
        end
      when :methods
        @method_counts[method_name] += 1
      when :receivers
        @receiver_counts[receiver_name] += 1 if receiver_name
      end
    end

    def receiver_name(node)
      return nil if node.nil?

      case node
      when ::Prism::ConstantReadNode, ::Prism::ConstantPathNode
        node.full_name.to_s if node.respond_to?(:full_name)
      when ::Prism::LocalVariableReadNode
        @config["split_variables"] ? "(var:#{node.name})" : "(var)"
      when ::Prism::InstanceVariableReadNode
        @config["split_variables"] ? "(ivar:#{node.name})" : "(ivar)"
      when ::Prism::ClassVariableReadNode
        @config["split_variables"] ? "(cvar:#{node.name})" : "(cvar)"
      when ::Prism::GlobalVariableReadNode
        @config["split_variables"] ? "(gvar:#{node.name})" : "(gvar)"
      when ::Prism::SelfNode
        "(self)"
      when ::Prism::CallNode
        "(result)"
      else
        nil
      end
    end

    def const_full_name(node)
      return nil if node.nil?
      return node.full_name.to_s if node.respond_to?(:full_name)
      nil
    end

    def extract_class_name(node)
      case node
      when ::Prism::ConstantReadNode
        node.name.to_s
      when ::Prism::ConstantPathNode
        node.full_name.to_s if node.respond_to?(:full_name)
      else
        nil
      end
    end

    def current_context_with_hash
      if @class_stack.empty?
        "#"
      else
        "#{@class_stack.join('::')}#"
      end
    end

    def receiver_type_matches?(rname, allowed_types)
      return false if rname.nil?

      if rname.start_with?("(var")
        allowed_types.include?("locals")
      elsif rname.start_with?("(ivar")
        allowed_types.include?("ivars")
      elsif rname.start_with?("(cvar")
        allowed_types.include?("cvars")
      elsif rname.start_with?("(gvar")
        allowed_types.include?("gvars")
      elsif rname.start_with?("(result)")
        allowed_types.include?("results")
      elsif rname.start_with?("(self)")
        # For future --only-self option
        allowed_types.include?("self")
      elsif rname.start_with?("#")
        # For nil receivers with include_nil_receiver
        allowed_types.include?("implicit")
      else
        # Constants like User, Post, etc.
        allowed_types.include?("constants")
      end
    end
  end
end
