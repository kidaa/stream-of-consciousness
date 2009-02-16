# -*- mode: ruby; -*-

    class StreamOfConsciousness
    
    attr_accessor :settings, :sideitems

    def initialize
      require 'cgi'
      require 'ftools' if RUBY_VERSION.to_f < 1.9
      require 'erb'
      
      settings={}
      @pageno=1
      @entries=[]
      @categories=[]
      @sideitems=[]
      @plugins=[]
      @templates={}
     
      eval(File.read('blog.conf.rb')) if File.exists?('blog.conf.rb')
      
      if (settings.nil?) then
        @settings = {
          
          :blog_title => "Blog Title",
          
          # What's this blog's description (for outgoing RSS feed)?
          :blog_description => "A Stream of Consciousness Blog",
          
          # What's this blog's primary language (for outgoing RSS feed)?
          :blog_language => "en",
          
          # Where are this blog's entries kept?
          :datadir => "/home/username/blogdata",
                    
          #What directory will static pages be served from?
          
          :pagedir => "/home/username/pagedata",
          
          :pagevar => "pages",
          
          # What's my preferred base URL for this blog (leave blank for automatic)?
          :url => "http://www.mysite.com",
          
          # How many entries should I show on the home page?
          :num_entries => 10,
          
          # What file extension signifies a blosxom entry?
          :file_extension => "txt",
          
          # What is the default flavour?
          :default_flavour => "html",      

          :plugindir => "/home/username/plugins",

          :themedir =>  "/home/username/theme"
          
        }        

      else
        @settings=settings
      end    


      @templates[:header]=%(
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
"http://www.w3.org/TR/html4/strict.dtd">

<html>
  <head>
   <meta http-equiv="Content-Type" content="text/html; charset=US-ASCII">
  <link rel="alternate" type="application/rss+xml" title="Recent (RSS)" href="/rss.xml" />

   <title><%=@settings[:blog_title]%></title>
    <style  type="text/css">
      <%=template :css %>
    </style>
    <%=do_hook('html_head') %>
  </head>
  <body>
   
      <div id="header">
	<span id="blogtitle"><%=@settings[:blog_title]%></span>
	<span id="blogsubtitle"><%=@settings[:blog_description]%></span>
      </div>
      <div id="content">
)
      @templates[:footer]=%( </div>
      <div id="footer">
	<a href="http://github.com/rsayers/stream-of-consciousness">Stream of Consciousness</a> - Blogging Minimilism<br>
	Code and content are Public Domain
      </div>
      
  </body>
</html>)
      @templates[:sidebar]=%(
	  <%unless @sideitems.nil? %>
	     <% @sideitems.each do |item| %>
	         <p class="sectiontitle"><%=item['title']%><p>
	         <%=item['content'].call %>
             <% end %>
        <% end %>)
      @templates['rss']=%(<?xml version="1.0"?>
                          <rss version="2.0">
                            <channel>
                            <title><%=@settings[:blog_title]%></title>
    <link><%=@settings[:url]%></link>
    <description><%=@settings[:blog_description]%></description>
    <pubDate><%=@entries.first.date%></pubDate>
    <generator>Stream of Consciousness</generator>
    <% @entries.each do |post| %>
 <item>
      <title><%= post.title %></title>
      <link><%= @settings[:url] %><%= post.category %>/<%= post.filename %></link>
      <description><![CDATA[<%= post.body %>]]></description>
      <pubDate><%=post.date%></pubDate>
      <guid><%=@settings[:url]%><%=post.category%>/<%=post.filename%></guid>
    </item>
<% end %>
  </channel>
</rss>)
      @templates[:layout]=%( 
<%=template :header%>

	<div id="left">
	  
	 <%=@block.call%>
	 </div>
	  <div id="right">
        
        <%=template :sidebar %>
	  </div>
	<%=template :footer%>)
@templates[:layout]=%(
<%=template :header%>
<div id="left">
<%=block.call if block_given? %>	  

	 </div>
	  <div id="right">
        <%=template :sidebar %>

	  </div>
	<%=template :footer%>
)
      
      @templates[:navigation]=%(<div id="nav">
<%
     if @pageno > 1 then
%>
         <a href="<%= [@settings[:url], @path_info.to_s ,@pageno.to_i - 1].join('/')%>">&lt;&lt;Prev</a> 
<%
    end
    if @pageno < @numpages then 
%>
      <a href="<%=[@settings[:url], @path_info.to_s ,@pageno.to_i + 1].join('/')%>">Next &gt;&gt;</a>
<%
    end
%></div>)

      
      @templates[:page]=%(<div class="post">
	    <div class="postheader">
	      <div class="title"><a href="<%=@settings[:url]%>/<%=@settings[:pagevar]%>/<%=@entry.filename%>"><%=@entry.title%></a></div>
	      
	    </div>
	    
	    <div class="postbody">
	     <%=@entry.body%>
	    </div>
	    
	  </div>)
      @templates[:entry]=%(<div class="post">
            <div class="postheader">

              <div class="title"><a href="<%=@settings[:url]%>/<%=@entry.category%>/<%=@entry.filename%>"><%=@entry.title%></a></div>

	      <div class="date"><%=@entry.date.strftime('%B %d %Y')%></div>
	    </div>
	    
	    <div class="postbody">
	     <%=@entry.body%>
	    </div>
	    <div class="postfooter">
	      Posted in <a href="<%=@settings[:url]%><%=@entry.category%>"><%=@entry.category%></a>
	    </div>
	    <hr>
	  </div>)

      @templates[:css]=%(
      * { font-family: Helvetica; }
      a { text-decoration: none; border-bottom: 1px dashed #929292;color:#929292; }
      body { padding-left: 10px; }
      #header { margin-bottom: 10px; width: 800px; border-top:5px solid black; background-color: #eeeeee}
      #left { width: 600px; float:left;}
      #content { width: 800px;}
      #right {float:right;text-align:center }
      #right ul { list-style: none; }
      #right ul li { background-color: #eeeeee;width:170px;margin-left:-50px; border-bottom:1px solid black;text-align:left; border-left:2px solid black; padding-left: 10px }
      #right ul li a { color: black; text-decoration:none; border-bottom: 0}
      .postbody { text-align: justify;font-size:11pt; font-family: times; letter-spacing: 1px; margin-bottom:10px;  }
      #footer { clear: both; }
      #blogtitle { font-size: 18pt; font-weight:bold; }
      #blogsubtitle { clear:both; display:block; font-family:Times; font-style: italic}
      .title { font-weight: bold; float:left;}
      .date {float: right; color: #929292}
      .postbody{border-top: 2px solid #929292; clear:both;}
      .postfooter { text-align: center; margin-bottom:20px;font-weight:bold }
      #footer { text-align: center; width:800px; background-color:#eeeeee;border-bottom:5px solid black}
      #nav { text-align: center; margin-bottom:10px; }
      pre,code {width:500px;overflow:auto; font-family:courier; font-size:11pt;letter-spacing:0px; background-color:#eeeeee}
      hr { display:none})


      load_plugins
            #load_template      
      get_categories
      get_pages

      @numpages=1


      # Default Side items,  page and category lists

      if (File.exist?(@settings[:pagedir])) then 
            
            @sideitems << {'title'=>'Pages','content'=>lambda{
            r='<ul>'
            @pages.each do |p|
              r+= "\t<li><a href=\"/#{@settings[:pagevar]}/#{p['filename']}\">#{p['title']}</a></li>"
            end 

            r+='</ul>'
            return r
          }} 
       end

      @sideitems << {'title'=>'Categories','content'=>lambda{
          r='<ul>'
          @categories.each do |c|
            r+=  "<li><a href=\"#{@settings[:url]}#{c}\">#{c}</a></li>"
          end           
          r+='</ul>'
          return r
        }}

      do_hook('sideitems')
    end
    

    
    
    def dispatch
      cgi=CGI.new
      cgi.header
      @mode=''
      @path_info=[]
      @path_info=cgi.path_info.to_s.split('/')
      
      @path_info.shift
      
      @path_info << '/' if @path_info.last.nil? 
      if @path_info.last.match(/\d+$/)
        @pageno=@path_info.pop.to_i

      end

      @path_info << '/' if @path_info.last.nil?
     
      output=''
      if @path_info.last.match('.*\.xml$') then 
        @mode='xml'
        cgi.header('Content-type: text/xml')
        @path_info.pop
        get_entries @path_info.join('/')
        puts template :rss
      elsif @path_info[0]=='pages'
        @mode='page'
        get_page
        puts template(:layout) {
          @entry=@entries.first
          template(:page) 
          
 
        }
        
        
      elsif @path_info.last.match('.*\.html$') then
        @mode='view'
        filename=@path_info.join('/')
        filename.gsub!('.html','.txt')
        if File.exist?(@settings[:datadir]+'/'+filename) then
          get_entry(filename)
          output=''
          @entry=@entries.first
          puts template(:layout) { 

            output << do_hook("before_single_entry")
            output << template(:entry) 
            
            output << do_hook("after_single_entry")
            
            output
            
          }
        else
          #error "Error: the requested entry was not found"
        end

      else
        @mode='list'
        

        if File.exist?( @settings[:datadir]+'/'+@path_info.join('/') ) then
          get_entries @path_info.join('/')   

          @path_info.pop
          do_hook('before_list_entry')
          puts template(:layout) { 
            
            @entries.each do |@entry|
              output << template(:entry)
            end
            output << template(:navigation)
            output
          }
        else

            error "Error: the specified entry was not found"

        end
      end
    end
    
   
    def load_plugins
      plugin_hook=''
      code=lambda{}
     return if !File.exist?(@settings[:plugindir])
     Dir.chdir(@settings[:plugindir])
      list=Dir.glob(File.join("**","*.rb"))
      list.each do |f|
        eval(File.read(@settings[:plugindir]+'/'+f))
        @plugins << { :hook => plugin_hook, :code => code }
      end
      
    end

    def template(name,&block)


     # begin
        tpl=ERB.new(@templates[name])
        tpl.result(binding)
      #rescue
      #  puts name
      #  exit
      #send
    end

    def do_hook(hook)
      @plugins.each do |p|
        
        if p[:hook]==hook then
          return p[:code].call
        end
      end
      ""
    end

    def get_entry(filename)

      @entries << load_entry(@settings[:datadir]+'/'+filename)
    end
 
   def get_page
      filename=@settings[:pagedir]+ '/' + @path_info.last
      filename.gsub!('.html','.txt')
      @entries << load_entry(filename)
    end

    def get_categories
      @categories=[]
      @categories << '/'
      Dir.chdir(@settings[:datadir])
      list=Dir.glob(File.join("**","*"))
      list.each do |e|
        @categories << '/'+e if FileTest.directory?(@settings[:datadir] + '/' + e)
      end
      @categories.sort! 
    end  
    
    def get_pages
      @pages=[]
      if (File.exist?(@settings[:pagedir])) then  
        Dir.chdir(@settings[:pagedir])
        list=Dir.glob(File.join("**","*.txt"))
        list.each do |e|
          @pages << {'filename'=>e.gsub('.txt','.html'),'title'=>File.open(e).readline}
        end
      end
    end
    

    def error(msg)
      template(:layout) {
        puts msg
      }
    end

    def load_entry(filename)
      
      
        File.open(filename) do |f|
          title=f.readline
          body=f.read.gsub("\r","").gsub("\n","<br>")
          date=f.mtime
          category="page"
          category=get_cat_from_file(filename) if @mode != "page" 
         tmp,filename=File.split(filename)
          Entry.new(title,body,date,category,filename)
        end
            
    end


    def get_cat_from_file(filename)


        fullpath=File.expand_path(filename)

        tmp,category=fullpath.split(@settings[:datadir])
        category,file=File.split(category)
        category

    end


    def get_entries(category='/')
      begin
        Dir.chdir(@settings[:datadir] + '/' + category )
      rescue
        
      end
      list=Dir.glob(File.join("**","*.#{@settings[:file_extension]}"))
      list.each do |post|
          @entries << load_entry(post)
      end
      @entries.sort! { |x,y| y.date <=> x.date }
      start = (@pageno.to_i * @settings[:num_entries].to_i) - @settings[:num_entries].to_i
      start = 0 if @pageno == 1
 		    
      @numpages=(@entries.length.to_f /  @settings[:num_entries].to_f).ceil
      @entries=@entries[start,@settings[:num_entries].to_i]
      do_hook('before_post');
    end
end

class Entry
  attr_accessor :title, :body, :date, :category, :filename
  def initialize(title,body,date,category,filename)
    @title=title
    @body=body
    @date=date
    @category=category
    @filename=filename.gsub('.txt','.html')
  end
end

settings={}


blog=StreamOfConsciousness.new
blog.dispatch

