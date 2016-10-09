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
      valid += params[:ISBN] +" and "
    end
    if (params[:by] & 0b10000) > 0
      valid += params[:price] +" and "
    end
    if (params[:by] & 0b100000) > 0
      valid += params[:publisher] +" and "
    end
    if (params[:by] & 0b1000000) > 0
      valid += params[:page] +" and "
    end
    return valid[0..valid.length-6]
  end

  soap_action "search",
              :args   => {:by => :integer, :name => :string, :author => :string,
                          :type => :string, :ISBN => :string,
                          :price => :string, :publisher => :string,
                          :page => :string},
              :return   => :string
  def search
    valid = parse_valid(params)
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
                          :type => :string, :ISBN => :string,
                          :price => :string, :publisher => :string,
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
                          :type => :string, :ISBN => :integer,
                          :price => :integer, :publisher => :string,
                          :page => :integer},
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
      isbn = Nokogiri::XML::Node.new "ISBN", $db
      isbn.content = params[:ISBN]
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

  # soap_action "plus",
  #             :args   => {:a => :integer, :b => :integer},
  #             :return   => :integer
  # def plus
  #   render :soap => (params[:a] + params[:b])
  # end
  #
  # soap_action "integer_to_string",
  #             :args   => :integer,
  #             :return => :string
  # def integer_to_string
  #   render :soap => params[:value].to_s
  # end
  #
  # soap_action "concat",
  #             :args   => { :a => :string, :b => :string },
  #             :return => :string
  # def concat
  #   render :soap => (params[:a] + params[:b])
  # end
  #
  # # Complex structures
  # soap_action "AddCircle",
  #             :args   => { :circle => { :center => { :x => :integer,
  #                                                    :y => :integer },
  #                                       :radius => :double } },
  #             :return => nil, # [] for wash_out below 0.3.0
  #             :to     => :add_circle
  # def add_circle
  #   circle = params[:circle]
  #
  #   raise SOAPError, "radius is too small" if circle[:radius] < 3.0
  #
  #   Circle.new(circle[:center][:x], circle[:center][:y], circle[:radius])
  #
  #   render :soap => nil
  # end
  #
  # # Arrays
  # soap_action "integers_to_boolean",
  #             :args => { :data => [:integer] },
  #             :return => [:boolean]
  # def integers_to_boolean
  #   render :soap => params[:data].map{|i| i > 0}
  # end
  #
  # # Params from XML attributes;
  # # e.g. for a request to the 'AddCircle' action:
  # #   <soapenv:Envelope>
  # #     <soapenv:Body>
  # #       <AddCircle>
  # #         <Circle radius="5.0">
  # #           <Center x="10" y="12" />
  # #         </Circle>
  # #       </AddCircle>
  # #     </soapenv:Body>
  # #   </soapenv:Envelope>
  # soap_action "AddCircle",
  #             :args   => { :circle => { :center => { :@x => :integer,
  #                                                    :@y => :integer },
  #                                       :@radius => :double } },
  #             :return => nil, # [] for wash_out below 0.3.0
  #             :to     => :add_circle
  # def add_circle
  #   circle = params[:circle]
  #   Circle.new(circle[:center][:x], circle[:center][:y], circle[:radius])
  #
  #   render :soap => nil
  # end
  #
  # # With a customised input tag name, in case params are wrapped;
  # # e.g. for a request to the 'IntegersToBoolean' action:
  # #   <soapenv:Envelope>
  # #     <soapenv:Body>
  # #       <MyRequest>  <!-- not <IntegersToBoolean> -->
  # #         <Data>...</Data>
  # #       </MyRequest>
  # #     </soapenv:Body>
  # #   </soapenv:Envelope>
  # soap_action "integers_to_boolean",
  #             :args => { :my_request => { :data => [:integer] } },
  #             :as => 'MyRequest',
  #             :return => [:boolean]

  # You can use all Rails features like filtering, too. A SOAP controller
  # is just like a normal controller with a special routing.
  before_filter :dump_parameters
  def dump_parameters
    Rails.logger.debug params.inspect
  end
end