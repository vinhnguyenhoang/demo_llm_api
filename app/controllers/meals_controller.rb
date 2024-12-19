class MealsController < ApplicationController

    # Trang nhập liệu tên món ăn
    def index
      # Action này chỉ hiển thị form nhập liệu tên món ăn
    end

    # Tìm kiếm món ăn từ API và hiển thị chi tiết
    def meal_details
      meal_name = params[:meal_name]
      if meal_name.present?
        meals = search_meal(meal_name)

        if meals.any?
          @meal_details = meals.map { |meal| get_meal_details(meal["idMeal"]) }
        else
          @message = "No meals found matching '#{meal_name}'"
        end
      end
    end

    private

    # Tìm kiếm món ăn từ API TheMealDB
    def search_meal_2(meal_name)
      query = CGI.escape(meal_name)  # Mã hóa tên món ăn
      url = URI("https://www.themealdb.com/api/json/v1/1/search.php?s=#{query}")
      response = Net::HTTP.get(url)
      result = JSON.parse(response)
    #   binding.pry
      # Nếu không tìm thấy kết quả, sử dụng fuzzy matching
      if result["meals"].nil? || result["meals"].empty?
        meals = fuzzy_search(meal_name)  # Sử dụng fuzzy search nếu không có kết quả chính xác
      else
        meals = result["meals"]
      end

      meals
    end

    # Tìm kiếm theo từng word được tách ra từ tên món ăn theo gợi ý của AI
    def search_meal(meal_name)
      # Phân tách tên món ăn thành các từ khóa
      keywords = meal_name.split(" ")

      # Tìm kiếm theo từng từ khóa
      search_results = []

      keywords.each do |keyword|
        query = CGI.escape(keyword)  # Mã hóa từ khóa
        url = URI("https://www.themealdb.com/api/json/v1/1/search.php?s=#{query}")
        response = Net::HTTP.get(url)
        result = JSON.parse(response)

        # Nếu có kết quả, thêm vào mảng search_results
        if result["meals"]
          search_results.concat(result["meals"])
        end
      end

      # Loại bỏ các món ăn trùng lặp (nếu có)
      search_results.uniq
      puts "Danh sách các món ăn tìm được:"
      search_results.each do |meal|
        puts meal["strMeal"]
      end
      # Sử dụng fuzzy_match để tìm món ăn gần giống nhất
      fm = FuzzyMatch.new(search_results.map { |meal| meal["strMeal"] })

      # Tìm kiếm 5 món ăn gần giống nhất với meal_name
      best_matches = fm.find_all(meal_name).take(5)

      puts "\nDanh sách các món ăn gần giống với '#{meal_name}':"
      best_matches.each do |match|
        puts match
      end
      # Lọc ra các món ăn gần giống nhất từ mảng `search_results`
      best_results = search_results.select do |meal|
        best_matches.include?(meal["strMeal"])
      end

      best_results
    end


    # Hàm fuzzy search tìm món ăn gần đúng
    def fuzzy_search(meal_name)
      url = URI("https://www.themealdb.com/api/json/v1/1/search.php?s=")
      response = Net::HTTP.get(url)
      result = JSON.parse(response)

      meals = result["meals"]

      # Dùng fuzzy_match để tìm kiếm gần đúng
      fm = FuzzyMatch.new(meals.map { |m| m['strMeal'] })
      best_match = fm.find(meal_name)  # Tìm món ăn có độ tương đồng cao nhất

      # Nếu có kết quả tìm gần đúng
      if best_match
        meals.select { |m| m['strMeal'] == best_match }
      else
        []
      end
    end

    # Lấy chi tiết món ăn từ API TheMealDB
    def get_meal_details(meal_id)
      url = URI("https://www.themealdb.com/api/json/v1/1/lookup.php?i=#{meal_id}")
      response = Net::HTTP.get(url)
      result = JSON.parse(response)
      result["meals"].first if result["meals"]
    end
  end
