class ProductUpdateJob < ApplicationJob
  queue_as :default

  def perform
    # Calculate one week ago from the current date
    one_week_ago = 1.week.ago

    products = Product.where("created_at <= ? AND url IS NOT NULL", one_week_ago)

    products.each do |product|
      update_product(product)
    end
  end

  private

  def update_product(product)
    begin
      scraped_data = product_data(product.url)
      product.update(scraped_data[:data])
      add_product_image(product, scraped_data[:image_url])
    rescue StandardError => e
      log_error(product, e)
    end
  end

  def product_data(url)
    scraper = FlipkartScraperService.new(url)
    scraper.scrape_data
  end

  def add_product_image(product, image_url)
    return unless image_url.present?

    image_data = URI.open(image_url)
    product.image.attach(io: image_data, filename: 'product_image.jpg')
  end

  def log_error(product, error)
    Rails.logger.error("Error updating product ##{product.id}: #{error.message}")
  end
end