$: << File.join(File.dirname(__FILE__), "..", "../lib")

require 'test/unit'
require 'deployapp/artifact_resolvers/namespace'
require 'deployapp/artifact_resolvers/product_store_artifact_resolver'
require 'deployapp/coord'

class DeployApp::ArtifactResolvers::ProductStoreArtifactResolverTest  < Test::Unit::TestCase
  def test_resolve_specific_version
    resolver = DeployApp::ArtifactResolvers::ProductStoreArtifactResolver.new(:appHome => "build", :artifactsDir => "build/")
    file = resolver.resolve(Coord.new(:name => "TIMConnect", :version => "1918", :type => "jar"))
    expectedArtifactPath = "build/TIMConnect-1918.jar"
    assert File.exists?(expectedArtifactPath), "expected #{expectedArtifactPath} to exist"
  end

  def test_resolve_different_artifact
    resolver = DeployApp::ArtifactResolvers::ProductStoreArtifactResolver.new(:appHome => "build", :artifactsDir => "build/")
    file = resolver.resolve(Coord.new(:name => "TIM-CSN", :version => "42", :type => "jar"))
    expectedArtifactPath = "build/TIM-CSN-42.jar"
    assert File.exists?(expectedArtifactPath), "expected #{expectedArtifactPath} to exist"
  end

  def test_resolve_fails_if_two_matching_artifacts
    resolver =  ProductStoreArtifactResolver.new(:appHome => "build", :artifactsDir => "build/")
    assert_raise(TooManyArtifacts) do
      file = resolver.resolve(Coord.new(:name => "TIMConnect", :version => "2001", :type => ""))
    end
  end

  def test_only_retains_n_old_artifacts
    resolver = DeployApp::ArtifactResolvers::ProductStoreArtifactResolver.new(:appHome => "build", :artifactsDir => "build/")
    file = resolver.resolve(Coord.new(:name => "TIMConnect", :version => "2001", :type => "jar"))
    file = resolver.resolve(Coord.new(:name => "TIMConnect", :version => "2002", :type => "jar"))
    file = resolver.resolve(Coord.new(:name => "TIMConnect", :version => "2003", :type => "jar"))
    file = resolver.resolve(Coord.new(:name => "TIMConnect", :version => "2004", :type => "jar"))
    file = resolver.resolve(Coord.new(:name => "TIMConnect", :version => "2005", :type => "jar"))
    file = resolver.resolve(Coord.new(:name => "TIMConnect", :version => "2006", :type => "jar"))
    file = resolver.resolve(Coord.new(:name => "TIMConnect", :version => "2001", :type => "jar"))
    file = resolver.resolve(Coord.new(:name => "TIMConnect", :version => "2007", :type => "jar"))

    assert_equal 5, Dir.glob("build/*.jar").size
  end

  def test_version_not_available
    resolver = DeployApp::ArtifactResolvers::ProductStoreArtifactResolver.new(:appHome => "build")

    assert_raise(ArtifactNotFound) do
      file = resolver.resolve(Coord.new(:name => "App", :version => "XXX"))
    end
  end

  def test_resolves_blondin
    resolver = DeployApp::ArtifactResolvers::ProductStoreArtifactResolver.new(:appHome => "build", :artifactsDir => "build/")
    file = resolver.resolve(Coord.new(:name => "Blondin", :version => "0.0.1.50", :type => "jar"))
    expectedArtifactPath = "build/Blondin-0.0.1.50.jar"
    assert File.exists?(expectedArtifactPath), "expected #{expectedArtifactPath} to exist"
  end
end
