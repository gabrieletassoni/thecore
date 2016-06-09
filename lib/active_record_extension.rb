module ActiveRecordExtension

  extend ActiveSupport::Concern

  # add your instance methods here
  # def foo
  #    "foo"
  # end

  # add your static(class) methods here
  module ClassMethods
    #E.g: Order.top_ten
    def top_ten
      limit(10)
    end

    def name_or_title_or_code_or_barcode_starts_with letter
      # Se ha name o code o barcode, uso uno di questi:
      column = if self.column_names.include? "name"
        :name
      elsif self.column_names.include? "title"
        :title
      elsif self.column_names.include? "code"
        :code
      elsif self.column_names.include? "barcode"
        :barcode
      end
      # Ecco la ricerca dedicata a Postgres, la facciamo multiplatform? Fatto
      query = "#{letter}%"
      match = arel_table[column].matches(query)
      where(match)
    end

    def starts_with_a
      name_or_title_or_code_or_barcode_starts_with :a
    end

    def starts_with_b
      name_or_title_or_code_or_barcode_starts_with :b
    end

    def starts_with_c
      name_or_title_or_code_or_barcode_starts_with :c
    end

    def starts_with_d
      name_or_title_or_code_or_barcode_starts_with :d
    end

    def starts_with_e
      name_or_title_or_code_or_barcode_starts_with :e
    end

    def starts_with_f
      name_or_title_or_code_or_barcode_starts_with :f
    end

    def starts_with_g
      name_or_title_or_code_or_barcode_starts_with :g
    end

    def starts_with_h
      name_or_title_or_code_or_barcode_starts_with :h
    end

    def starts_with_i
      name_or_title_or_code_or_barcode_starts_with :i
    end

    def starts_with_j
      name_or_title_or_code_or_barcode_starts_with :j
    end

    def starts_with_k
      name_or_title_or_code_or_barcode_starts_with :k
    end

    def starts_with_l
      name_or_title_or_code_or_barcode_starts_with :l
    end

    def starts_with_m
      name_or_title_or_code_or_barcode_starts_with :m
    end

    def starts_with_n
      name_or_title_or_code_or_barcode_starts_with :n
    end

    def starts_with_o
      name_or_title_or_code_or_barcode_starts_with :o
    end

    def starts_with_p
      name_or_title_or_code_or_barcode_starts_with :p
    end

    def starts_with_q
      name_or_title_or_code_or_barcode_starts_with :q
    end

    def starts_with_r
      name_or_title_or_code_or_barcode_starts_with :r
    end

    def starts_with_s
      name_or_title_or_code_or_barcode_starts_with :s
    end

    def starts_with_t
      name_or_title_or_code_or_barcode_starts_with :t
    end

    def starts_with_u
      name_or_title_or_code_or_barcode_starts_with :u
    end

    def starts_with_v
      name_or_title_or_code_or_barcode_starts_with :v
    end

    def starts_with_w
      name_or_title_or_code_or_barcode_starts_with :w
    end

    def starts_with_x
      name_or_title_or_code_or_barcode_starts_with :x
    end

    def starts_with_y
      name_or_title_or_code_or_barcode_starts_with :y
    end

    def starts_with_z
      name_or_title_or_code_or_barcode_starts_with :z
    end
  end
end

# include the extension
ActiveRecord::Base.send(:include, ActiveRecordExtension)
