# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rdf}
  s.version = "0.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Arto Bendiken", "Ben Lavender"]
  s.date = %q{2010-07-05}
  s.default_executable = %q{rdf}
  s.description = %q{RDF.rb is a pure-Ruby library for working with Resource Description Framework (RDF) data.}
  s.email = %q{public-rdf-ruby@w3.org}
  s.executables = ["rdf"]
  s.files = ["AUTHORS", "CONTRIBUTORS", "README", "UNLICENSE", "VERSION", "bin/rdf", "etc/doap.nt", "lib/df.rb", "lib/rdf/cli.rb", "lib/rdf/format.rb", "lib/rdf/mixin/countable.rb", "lib/rdf/mixin/durable.rb", "lib/rdf/mixin/enumerable.rb", "lib/rdf/mixin/inferable.rb", "lib/rdf/mixin/mutable.rb", "lib/rdf/mixin/queryable.rb", "lib/rdf/mixin/readable.rb", "lib/rdf/mixin/writable.rb", "lib/rdf/model/graph.rb", "lib/rdf/model/literal/boolean.rb", "lib/rdf/model/literal/date.rb", "lib/rdf/model/literal/datetime.rb", "lib/rdf/model/literal/decimal.rb", "lib/rdf/model/literal/double.rb", "lib/rdf/model/literal/integer.rb", "lib/rdf/model/literal/time.rb", "lib/rdf/model/literal/xml.rb", "lib/rdf/model/literal.rb", "lib/rdf/model/node.rb", "lib/rdf/model/resource.rb", "lib/rdf/model/statement.rb", "lib/rdf/model/uri.rb", "lib/rdf/model/value.rb", "lib/rdf/nquads.rb", "lib/rdf/ntriples/format.rb", "lib/rdf/ntriples/reader.rb", "lib/rdf/ntriples/writer.rb", "lib/rdf/ntriples.rb", "lib/rdf/query/pattern.rb", "lib/rdf/query/solution.rb", "lib/rdf/query/variable.rb", "lib/rdf/query.rb", "lib/rdf/reader.rb", "lib/rdf/repository.rb", "lib/rdf/util/aliasing.rb", "lib/rdf/util/cache.rb", "lib/rdf/util.rb", "lib/rdf/version.rb", "lib/rdf/vocab/cc.rb", "lib/rdf/vocab/cert.rb", "lib/rdf/vocab/dc.rb", "lib/rdf/vocab/dc11.rb", "lib/rdf/vocab/doap.rb", "lib/rdf/vocab/exif.rb", "lib/rdf/vocab/foaf.rb", "lib/rdf/vocab/geo.rb", "lib/rdf/vocab/http.rb", "lib/rdf/vocab/owl.rb", "lib/rdf/vocab/rdfs.rb", "lib/rdf/vocab/rsa.rb", "lib/rdf/vocab/rss.rb", "lib/rdf/vocab/sioc.rb", "lib/rdf/vocab/skos.rb", "lib/rdf/vocab/wot.rb", "lib/rdf/vocab/xhtml.rb", "lib/rdf/vocab/xsd.rb", "lib/rdf/vocab.rb", "lib/rdf/writer.rb", "lib/rdf.rb"]
  s.homepage = %q{http://rdf.rubyforge.org/}
  s.licenses = ["Public Domain"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.1")
  s.rubyforge_project = %q{rdf}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{A Ruby library for working with Resource Description Framework (RDF) data.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<addressable>, ["~> 2.1.2"])
      s.add_development_dependency(%q<yard>, [">= 0.5.8"])
      s.add_development_dependency(%q<rspec>, [">= 1.3.0"])
      s.add_development_dependency(%q<rdf-spec>, ["~> 0.2.2"])
    else
      s.add_dependency(%q<addressable>, ["~> 2.1.2"])
      s.add_dependency(%q<yard>, [">= 0.5.8"])
      s.add_dependency(%q<rspec>, [">= 1.3.0"])
      s.add_dependency(%q<rdf-spec>, ["~> 0.2.2"])
    end
  else
    s.add_dependency(%q<addressable>, ["~> 2.1.2"])
    s.add_dependency(%q<yard>, [">= 0.5.8"])
    s.add_dependency(%q<rspec>, [">= 1.3.0"])
    s.add_dependency(%q<rdf-spec>, ["~> 0.2.2"])
  end
end
