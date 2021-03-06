module TermApp
  # Less editor for terminal. Used for reading posts.
  class LessEditor < Editor
    def show(str: '') # readonly
      # TODO: alt key handling (http://stackoverflow.com/a/16248956).
      erase_all
      Line.column = @term.columns
      str = "\n" if str == ''
      @lines = str.split("\n", -1).map { |x| Line.new(x) }
      Ncurses.noecho
      @start_y = 0
      key = nil
      total_lines = @lines.map(&:ymax).reduce(:+) || 0
      term_lines = @term.lines - 1
      loop do
        if key.nil?
          # TODO: Print footer and do not erase footer.
          erase_all
          i = 0
          @lines.each do |x|
            if i < @start_y
              if i + x.ymax <= @start_y
                i += x.ymax
                next
              else
                mvaddstr(0, 0, x.to_s(@start_y - i))
              end
            else
              mvaddstr(i - @start_y, 0, x.to_s)
            end
            i = getyx[0] + 1 + @start_y
            break if i >= @start_y + term_lines
          end
          key = get_wch
        end
        case KeyHelper.key_symbol(key)
        when *@exit_on
          return key
        when :j, :down
          if @start_y + term_lines >= total_lines
            beep
          else
            @start_y += 1
          end
        when :k, :up
          if @start_y == 0
            beep
          else
            @start_y -= 1
          end
        when :q, :Q
          return nil, key
        when :space
          if @start_y + term_lines >= total_lines
            return key
          end
          @start_y += term_lines - 1
          @start_y = total_lines - term_lines if @start_y + term_lines >=
                                                 total_lines
        end
        key = nil
      end
    end
    # End of def method show.

    def gety
      (@lines[0...@str_idx].map(&:ymax).reduce(:+) || 0) + @str_y_idx - @start_y
    end
  end
  # End of def class LessEditor.
end
