U = 'users-guide' unless defined?(U)
docdir = '../doc'
#website_tagfile = 'kuwata-lab'
website_tagfile = 'site-design.ktag'
html_tagfile    = 'html-css_i'

material 'index.txt'

##
##  recipes for kuwata-lab.com
##
#all = %W[index.xhtml README.xhtml #{U}.01.xhtml ChangeLog.txt]
all = %W[index.xhtml #{U}.01.xhtml ChangeLog]

recipe  :default		, :all

recipe  :all			, all
	
recipe  :clean								do
	files = []
	files.concat Dir.glob("README.*")
	files.concat Dir.glob("ChangeLog")
	files.concat Dir.glob("#{U}.*")
	files.concat(%w[m18n.rb guide.d index.xhtml])
	rm_rf [files]
	end

recipe  "#{U}.txt"		, "../doc/#{U}.txt"		do
	cp @ingred, @product
	end

recipe	"#{U}.01.xhtml"	, "#{U}.txt", :byprods=>["#{U}.toc.html"]  do
	tagfile = website_tagfile
	dir = "guide.d"
	rm_rf dir
	mkdir_p dir
	sys "retrieve -d #{dir} #{@ingred}"
	## -b: .profile and breadcrumbs, -s: separate, -n: number
	sys "kwaser -t #{tagfile} -bsn -T2 #{@ingred} > #{@byprods[0]}"
	sys "kwaser -t #{tagfile} -bsn     #{@ingred}"
        files = Dir.glob("#{U}.??.html")
        files << "#{U}.html"
        #p files
        files.each do |old|
          new = old.sub(/\.html$/, '.xhtml')
          File.rename(old, new) if old != new
    	end
	rm_f @byprods
	end

#recipe	'README.xhtml'		, '../README'			do
#	tagfile = website_tagfile
#	sys "kwaser -t #{tagfile} -b #{@ingred} > #{@product}" 
#	end

recipe	"index.xhtml"		, "index.txt",
				 :byprods=>%w[data.yaml example.eruby]	do
	tagfile = website_tagfile
	sys "retrieve #{@ingred}"
        sys "kwaser -t #{tagfile} -b #{@ingred} > #{@product}"
	rm_f @byprods
	end

#recipe	"ChangeLog.html"		, "../ChangeLog"		do
#	tagfile = website_tagfile
#	sys "kwaser -t #{tagfile} -b #{@ingred} > #{@product}"
#	end

recipe	"ChangeLog"			, "../ChangeLog"		do
	#copy r.ingreds[0], r.product
	cp @ingred, "."
	end

