module ActionDispatch
  module Routing
    class Mapper
      class Mapping

        def need_postfix?(path)
          !['/assets', '/', '/rails/info/properties', '/rails/info/routes', '/rails/info', '/rails/mailers', '/rails/mailers/*path'].include?(path)
        end

        def initialize(scope, set, path, defaults, as, options)
          @requirements, @conditions = {}, {}
          @defaults = defaults
          @set = set

          @to                 = options.delete :to
          @default_controller = options.delete(:controller) || scope[:controller]
          @default_action     = options.delete(:action) || scope[:action]
          @as                 = as
          @anchor             = options.delete :anchor

          formatted = options.delete :format
          via = Array(options.delete(:via) { [] })
          options_constraints = options.delete :constraints

          path = normalize_path! path, false
          path = path + '.php' if need_postfix?(path)
          ast = path_ast path
          path_params = path_params ast

          options = normalize_options!(options, formatted, path_params, ast, scope[:module])

          split_constraints(path_params, scope[:constraints]) if scope[:constraints]
          constraints = constraints(options, path_params)

          split_constraints path_params, constraints

          @blocks = blocks(options_constraints, scope[:blocks])

          if options_constraints.is_a?(Hash)
            split_constraints path_params, options_constraints
            options_constraints.each do |key, default|
              if URL_OPTIONS.include?(key) && (String === default || Fixnum === default)
                @defaults[key] ||= default
              end
            end
          end

          normalize_format!(formatted)

          @conditions[:path_info] = path
          @conditions[:parsed_path_info] = ast

          add_request_method(via, @conditions)
          normalize_defaults!(options)
        end
      end

      module Resources
        def add_route(action, options) # :nodoc:
          path, params = path_for_action(action, options.delete(:path))
          raise ArgumentError, "path is required" if path.blank?

          action = action.to_s.dup

          if action =~ /^[\w\-\/]+$/
            options[:action] ||= action.tr('-', '_') unless action.include?("/")
          else
            action = nil
          end

          as = if !options.fetch(:as, true) # if it's set to nil or false
                 options.delete(:as)
               else
                 name_for_action(options.delete(:as), action)
               end

          mapping = Mapping.build(@scope, @set, URI.parser.escape(path), as, options)
          app, conditions, requirements, defaults, as, anchor = mapping.to_route
          path_params = params
          @set.add_route(app, conditions, requirements, defaults, as, anchor, path_params)
        end

        def path_for_action(action, path) #:nodoc:
          if path.blank? && resource_method_scope? && ['index', 'new'].include?(action.to_s)
            [@scope[:path].to_s, []]
          elsif path.blank? && resource_method_scope?
            case @scope.scope_level
            when :collection
              path = action_path(action, path)
              ["#{@scope[:path]}/#{path}", []]
            when :member
              path = action_path(action, path)
              param = @scope[:path].match(/\/:(\w+)$/)[1].to_sym
              ["#{@scope[:path].gsub(/\/:(\w+)$/, '')}/#{path}", [param]]
            end
          else
            path = action_path(action, path)
            params = path.scan(/\/:(\w+)/).flatten.map(&:to_sym)
            path = path.gsub(/\/:(\w+)/, '')
            ["#{@scope[:path]}/#{path}", params]
          end
        end
      end
    end

    class RouteSet
      def add_route(app, conditions = {}, requirements = {}, defaults = {}, name = nil, anchor = true, path_params = [])
        raise ArgumentError, "Invalid route name: '#{name}'" unless name.blank? || name.to_s.match(/^[_a-z]\w*$/i)

        if name && named_routes[name]
          raise ArgumentError, "Invalid route name, already in use: '#{name}' \n" \
            "You may have defined two routes with the same name using the `:as` option, or " \
            "you may be overriding a route already defined by a resource with the same naming. " \
            "For the latter, you can restrict the routes created with `resources` as explained here: \n" \
            "http://guides.rubyonrails.org/routing.html#restricting-the-routes-created"
        end

        path = conditions.delete :path_info
        ast  = conditions.delete :parsed_path_info
        path = build_path(path, ast, requirements, anchor)
        conditions = build_conditions(conditions, path.names.map { |x| x.to_sym })

        route = @set.add_route(app, path, conditions, defaults, name)
        route.instance_eval{@path_params = path_params}
        named_routes[name] = route if name
        route
      end

      class NamedRouteCollection
        class UrlHelper
          def initialize(route, options, route_name, url_strategy)
            @options      = options
            @segment_keys = route.segment_keys.uniq + route.instance_eval{@path_params}
            @route        = route
            @url_strategy = url_strategy
            @route_name   = route_name
          end
        end
      end
    end
  end
end

module ActionDispatch
  module ResetHeader
    def initialize
      ret = super
      self.headers['Server'] = 'php/5.4'
      self.headers['X-Powered-By'] = 'php/5.4'
      ret
    end
  end

  Response.prepend ResetHeader
end