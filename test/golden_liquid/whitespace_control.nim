[
  {
    "name": "don't suppress whitespace only blocks containing echo",
    "template": "!{% if true %}\n\n{% assign bar = 'foo' %}\n    {% echo '' %}\n\n    {% assign foo = 'bar' %}\n\n\n\n{% endif %}!",
    "want": "!\n\n\n    \n\n    \n\n\n\n!",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "don't suppress whitespace only blocks containing output",
    "template": "!{% if true %}\n\n{% assign bar = 'foo' %}\n    {{ '' }}\n\n    {% assign foo = 'bar' %}\n\n\n\n{% endif %}!",
    "want": "!\n\n\n    \n\n    \n\n\n\n!",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "don't suppress whitespace only blocks containing output in nested block",
    "template": "!{% if 1 %}\n\n{% assign bar = 'foo' %}\n{% if 2 %}\n    {{ '' }}\n\n    {% assign foo = 'bar' %}\n\n{% endif %}\n\n\n{% endif %}!",
    "want": "!\n\n\n\n    \n\n    \n\n\n\n\n!",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "don't suppress whitespace only blocks containing output in unreachable blocks",
    "template": "!{% if 1 %}\n\n{% assign bar = 'foo' %}\n{% if true %}\n\n    {% assign foo = 'bar' %}\n\n{% else %}\n    {{ '' }}\n{% endif %}\n\n\n{% endif %}!",
    "want": "!\n\n\n\n\n    \n\n\n\n\n!",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "don't suppress whitespace only case blocks containing output",
    "template": "!{% assign x = 1 %}{% case x %}\n\n  {% when 1 %}\n    {% assign foo = 'bar' %}\n\n  {% when 2 %}\n    {{ '' }}\n\n{% endcase %}!",
    "want": "!\n    \n\n  !",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "don't suppress whitespace only unless blocks containing output in nested blocks",
    "template": "!{% unless false %}\n\n{% assign bar = 'foo' %}\n{% unless false %}\n    {{ '' }}\n\n    {% assign foo = 'bar' %}\n\n{% endunless %}\n\n\n{% endunless %}!",
    "want": "!\n\n\n\n    \n\n    \n\n\n\n\n!",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "suppress whitespace only case blocks",
    "template": "!{% assign x = 1 %}{% case x %}\n\n  {% when 1 %}\n    {% assign foo = 'bar' %}\n\n\n{% endcase %}!",
    "want": "!!",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "suppress whitespace only if blocks",
    "template": "!{% if true %}\n\n{% assign bar = 'foo' %}\n{% if true %}\n\n\n    {% assign foo = 'bar' %}\n\n{% endif %}\n\n\n{% endif %}!",
    "want": "!!",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "suppress whitespace only unless blocks",
    "template": "!{% unless false %}\n\n{% assign bar = 'foo' %}\n{% unless false %}\n\n\n    {% assign foo = 'bar' %}\n\n{% endunless %}\n\n\n{% endunless %}!",
    "want": "!!",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "suppress whitespace surrounding a capture block",
    "template": "!{% if true %}\n\n{% capture foo %}\n{{ '' }}\n{% endcapture %}\n\n{% endif %}!",
    "want": "!!",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "suppress whitespace surrounding an empty capture block",
    "template": "!{% if true %}\n\n{% capture foo %}{% endcapture %}\n\n{% endif %}!",
    "want": "!!",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "white space control with  carriage return, newline and spaces",
    "template": "\r\n{% if customer -%}\r\nWelcome back,  {{ customer.first_name -}} !\r\n {%- endif -%}",
    "want": "\r\nWelcome back,  Holly!",
    "context": {
      "customer": {
        "first_name": "Holly"
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "white space control with carriage return and spaces",
    "template": "\r{% if customer -%}\rWelcome back,  {{ customer.first_name -}} !\r {%- endif -%}",
    "want": "\rWelcome back,  Holly!",
    "context": {
      "customer": {
        "first_name": "Holly"
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "white space control with newlines and spaces",
    "template": "\n{% if customer -%}\nWelcome back,  {{ customer.first_name -}} !\n {%- endif -%}",
    "want": "\nWelcome back,  Holly!",
    "context": {
      "customer": {
        "first_name": "Holly"
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "white space control with newlines, tabs and spaces",
    "template": "\n\t{% if customer -%}\t\nWelcome back,  {{ customer.first_name -}}\t !\r\n {%- endif -%}",
    "want": "\n\tWelcome back,  Holly!",
    "context": {
      "customer": {
        "first_name": "Holly"
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "white space control with raw tags",
    "template": "! {% raw %}{{ hello }}{% endraw %} !\n! {%- raw -%}{{ hello }}{%- endraw -%} !",
    "want": "! {{ hello }} !\n!{{ hello }}!",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]