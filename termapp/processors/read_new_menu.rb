module TermApp
  # Corresponding Processor of LocoMenu::Item.new('New', :read_new_menu).
  class ReadNewMenu < Processor
    def process
      term.noecho
      st = Time.now.to_i
      flash = nil
      Board.each_leaves do |b|
        next if b.zapped_by? term.current_user
        orig_board = b
        b = b.alias_board while b.alias_board
        list = BoardRead.where(user: term.current_user)
               .where(board: b).order('lower(posts)').to_a
        num = 1
        max_num = b.max_num
        while num <= max_num
          if !list.empty? && list[0].posts.cover?(num)
            num = list[0].posts.max + 1
            list.shift
            next
          end
          post = b.post.find_by(num: num)
          term.erase_body
          strs = []
          strs << "[새글 읽기: #{orig_board.path_name} ( #{b.owner.username} )]"
          strs << "   남은글 : #{max_num - post.num + 1}개"
          strs << "   제  목 : \"#{post.title}\""
          strs << "   글쓴이 : #{post.writer.username}"
          strs << '   조회수 : ??'
          strs << '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
          strs << ' (SP,n,j,\n)읽기 (v)통과 (V)게시판visit (Q)마치기 (S)게시판통과 (Z)Zap'
          strs << '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
          strs.each_with_index do |x, i|
            term.mvaddstr(2 + i, 0, x)
          end
          term.mvaddstr(11, 0, flash) if flash
          flash = nil
          key = term.get_wch
          control, *args = process_key(key)
          case control
          when :quit
            term.echo
            return args
          when :zap
            flash = 'Zap is currently not supported'
            # disable zap for now
            # (because unzap is not implemented)
            # ZapBoard.zap(orig_board,term.current_user)
            break
          when :visit_all
            flash = 'Mark visit on board is currently not supported'
          when :visit
            BoardRead.mark_visit(term.current_user, post, b)
            num += 1
          when :read
            case read_post(post)
            when :quit
              term.echo
              return :loco_menu
            end
            num += 1
          when :break then break args
          when :beep  then term.beep
          end
        end
      end
      dur = Time.now.to_i - st
      term.erase_body
      term.mvaddstr(5, 5, "took #{dur} seconds")
      term.get_wch
      term.echo
      :loco_menu
    end

    def process_key(key)
      case KeyHelper.key_symbol(key)
      when :q
        return :quit, :loco_menu
      when :s
        return :break
      when :z
        return :zap
      when :v
        return :visit
      when :space, :enter, :n, :j
        return :read
      end
    end

    def read_post(post)
      post.read_status = nil
      read_post_helper = ReadPostHelper.new(@app, post)
      result = read_post_helper.read_post
      case KeyHelper.key_symbol(result[1])
      when :q then :quit
      else nil
      end
    end
  end
end