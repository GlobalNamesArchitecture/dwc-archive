class DarwinCore
  class Error < RuntimeError; end
  class FileNotFoundError < Error; end
  class UnpackingError < Error; end
  class InvalidArchiveError < Error; end
  class CoreFileError < Error; end
  class ExtensionFileError < Error; end
  class GeneratorError < Error; end
  class ParentNotCurrentError < Error; end
end
