module TermApp
  class View
    # Internal: Initialize a View. It holds the Application instance.
    #
    # app - The Application instance which is now running.
    def initialize(app)
      @app = app
    end

    # Internal: Delegates all missing methods to the application.
    #
    # meth - The Symbol of a missing method.
    # args - Zero or more values to pass to method as parameters.
    def method_missing(meth, *args)
      @app.send(meth, *args)
    end
  end
end
