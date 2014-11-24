# Title:
#		Jekyll/Octopress external link tag
# Author:
#		Hanns Holger Rutz
# Syntax:
#		{% extlink link-text... url/to/link %}
# Example:
#		{% extlink some music http://example.org/music.mp3 %}
# Output:
#		<a href="http://example.org/music.mp3" class="external" target="_blank">some music</a>

module Jekyll
  class ExtLinkTag < Liquid::Tag
    @text = ''
    @link = ''

    def initialize(tag_name, markup, tokens)
      if markup =~ /(.+)(\s+(https?:\S+))/i
        @text = $1
        @link = $3
        # puts "text: "+@text
        # puts "link: "+@link
      end
      super
    end

    def render(context)
      output = super
      "<a class='external' target='_blank' href='"+@link+"'>"+@text+"</a>"
    end
  end
end

Liquid::Template.register_tag('extlink', Jekyll::ExtLinkTag)
