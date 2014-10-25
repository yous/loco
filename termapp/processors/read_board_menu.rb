module TermApp
  # Corresponding Processor of LocoMenu::Item.new('Read', :read_board_menu).
  # Print the Post list of current Board.
  class ReadBoardMenu < Processor
    def process
      term.erase_body
      unless term.current_board
        term.mvaddstr(8, 8, '보드를 먼저 선택해 주세요')
        term.getch
        return :loco_menu
      end
      process_init
      term.noecho
      result = loop do
        if @cur_index.nil? || @cur_index >= @num_lists
          @cur_index = @num_lists - 1
        end
        print_posts
        @past_index = @cur_index
        control, *args = process_key(term.getch)
        case control
        when :break
          break args
        when :beep
          term.beep
        when :scroll_down
          scroll(:down)
        when :scroll_up
          scroll(:up)
        end
      end
      term.echo
      result
    end

    private

    # Initialize instance variables before actual processing.
    #
    # Returns nothing.
    def process_init
      cur_board = term.current_board
      @cur_index = nil
      @past_index = nil
      @num_lists = term.lines - 5
      @posts = cur_board.post.order('num desc').limit(@num_lists).reverse
      @edge_posts = [cur_board.post.first, cur_board.post.last]
    end

    # Process key input for ReadBoardMenu.
    #
    # key - A Integer key input which is returned from term.getch.
    #
    # Returns nil or a Symbol :beep, :scroll_down, :scroll_up or :break with
    #   additional arguments.
    def process_key(key)
      case key
      when 27, 113 # ESC, q
        return :break, :loco_menu
      when 10, 32 # enter, space
        return :break, :loco_menu # FIXME : read post
      when Ncurses::KEY_DOWN, 106 # j
        if @cur_index == @num_lists - 1
          return :scroll_down
        else
          @cur_index += 1
        end
      when Ncurses::KEY_UP, 107 # k
        if @cur_index == 0
          return :scroll_up
        else
          @cur_index -= 1
        end
      when 74 # J
        return :beep # TODO : scroll to end of list
      else
        return :beep
      end
    end

    # Check if the page can be scrolled with given direction.
    #
    # direction - A Symbol one of :down or :up.
    #
    # Returns a Boolean whether the page can be scrolled.
    def scrollable?(direction)
      case direction
      when :down
        pivot = @posts[-1]
        return pivot && pivot != @edge_posts[1]
      when :up
        pivot = @posts[0]
        return pivot && pivot != @edge_posts[0]
      end
    end

    # Scroll the page of Posts.
    #
    # direction - A Symbol indicates direction. It can be :down or :up.
    #
    # Returns nothing.
    def scroll(direction)
      unless scrollable?(direction)
        term.beep
        return
      end
      cur_board = term.current_board
      case direction
      when :down
        @past_index = nil
        @cur_index = 1
        @posts = cur_board.post.order('num asc').limit(@num_lists)
                          .where('num >= ?', @posts[-1].num)
        if @posts.size < @num_lists # reached last
          @cur_index = @num_lists - @posts.size + 1
          @posts = cur_board.post.order('num desc').limit(@num_lists).reverse
        end
      when :up
        @past_index = nil
        @cur_index = @num_lists - 2
        @posts = cur_board.post.order('num desc').limit(@num_lists)
                          .where('num <= ?', @posts[0].num).reverse
        if @posts.size < @num_lists # reached first
          @cur_index = @posts.size - 2
          @posts = cur_board.post.order('num asc').limit(@num_lists)
        end
      end
    end

    # Print Post list. Current Post is displayed in reversed color. Refresh only
    # highlighted lines if the list hasn't been scrolled.
    #
    # Returns nothing.
    def print_posts
      if @past_index.nil?
        term.erase_body
        @posts.each_with_index do |post, i|
          term.color_black(reverse: true) if @cur_index == i
          term.mvaddstr(i + 4, 0, post.format_for_term(term.columns - 32))
          term.color_black # reset color
        end
      else
        return if @past_index == @cur_index
        term.mvaddstr(@past_index + 4, 0,
                      @posts[@past_index].format_for_term(term.columns - 32))
        term.color_black(reverse: true) do
          term.mvaddstr(@cur_index + 4, 0,
                        @posts[@cur_index].format_for_term(term.columns - 32))
        end
      end
      term.mvaddstr(@cur_index + 4, 0, '>')
      term.refresh
    end
  end
end
