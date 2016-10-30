require 'nokogiri'
PATH = 'xmldb/books.xml'
$file = open(PATH)
$db = Nokogiri::XML $file.read
# $book_store = $db.at_css("book_store")
$file.close

class RumbasController < ApplicationController
  soap_service namespace: 'urn:WashOut'

  # Simple case
  def parse_valid(params)
    valid = ""
    if (params[:by] & 0b1) > 0
      valid += params[:name] +" and "
    end
    if (params[:by] & 0b10) > 0
      valid += params[:author] +" and "
    end
    if (params[:by] & 0b100) > 0
      valid += params[:type] +" and "
    end
    if (params[:by] & 0b1000) > 0
      valid += params[:publisher] +" and "
    end
    if (params[:by] & 0b10000) > 0
      valid += params[:isbn] +" and "
    end
    if (params[:by] & 0b100000) > 0
      valid += params[:price] +" and "
    end
    if (params[:by] & 0b1000000) > 0
      valid += params[:page] +" and "
    end
    return valid[0..valid.length-6]
  end

  soap_action "search",
              :args   => {:by => :integer, :name => :string, :author => :string,
                          :type => :string, :publisher => :string,
                          :isbn => :string, :price => :string,
                          :page => :string},
              :return   => :string
  def search
    valid = parse_valid(params)
    print valid
    choose = "<result>"+$db.search("//book["+valid+"]").to_s+"</result>"
    render :soap => choose
  end

  # remove factor by bits from integer
  # 1 => name
  # 2 => author
  # 3 => type
  # 4 => ISBN
  # 5 => price
  # 6 => publisher
  # 7 => page

  soap_action "remove",
              :args   => {:by => :integer, :name => :string, :author => :string,
                          :type => :string, :publisher => :string,
                          :isbn => :string, :price => :string,
                          :page => :string},
              :return   => :integer # number of removed object
  def remove
    valid = parse_valid(params)
    # puts valid
    choose = $db.search("//book["+valid+"]").remove
    size = 0
    for i in choose
      size += 1
    end
    $file = open PATH, "w"
    $file.write $db
    $file.close
    render :soap => "<result>"+size.to_s+"</result>"
  end


  soap_action "add",
              :args   => {:name => :string, :author => :string,
                          :type => :string, :publisher => :string,
                          :isbn => :string, :price => :string,
                          :page => :string},
              :return   => :integer
  def add
    begin
      book = Nokogiri::XML::Node.new "book", $db
      name = Nokogiri::XML::Node.new "name", $db
      name.content = params[:name]
      name.parent = book
      author = Nokogiri::XML::Node.new "author", $db
      author.content = params[:author]
      author.parent = book
      type = Nokogiri::XML::Node.new "type", $db
      type.content = params[:type]
      type.parent = book
      price = Nokogiri::XML::Node.new "price", $db
      price.content = params[:price]
      price.parent = book
      publisher = Nokogiri::XML::Node.new "publisher", $db
      publisher.content = params[:publisher]
      publisher.parent = book
      page = Nokogiri::XML::Node.new "page", $db
      page.content = params[:page]
      page.parent = book
      isbn = Nokogiri::XML::Node.new "isbn", $db
      isbn.content = params[:isbn]
      isbn.parent = book
      # book.parent = $book_store
      last_book = $db.xpath("//book").last
      last_book.add_next_sibling book
      $file = open PATH, "w"
      $file.write $db
      $file.close
      render :soap => "<result>"+1.to_s+"</result>"
    rescue
      render :soap => "<result>"+0.to_s+"</result>"
    end
  end

  before_filter :dump_parameters
  def dump_parameters
    Rails.logger.debug params.inspect
  end
end
