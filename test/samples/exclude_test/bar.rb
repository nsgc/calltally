class Bar
  def process
    data = fetch_data
    data.each { |item| handle(item) }
  end

  def fetch_data
    ["a", "b", "c"]
  end

  def handle(item)
    item.upcase
  end
end
