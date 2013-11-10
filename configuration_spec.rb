require 'rspec/autorun'
require_relative 'configuration'
require 'tempfile'

describe Configuration do
  subject(:configuration) { described_class.new tempfile_path }
  let(:tempfile_path) { f = Tempfile.new('configuration_spec'); f.write test_data; f.close; f.path }
  let(:test_data) { File.read 'example.cfg' }

  describe '#[]' do
    it 'accesses config values by section and key name as strings' do
      expect(configuration[header: 'project']).to eq 'Programming Test'
      expect(configuration['meta data' => 'correction text']).to eq "I meant 'moderately,' not 'tediously,' above."
      expect(configuration[trailer: 'budget']).to eq 'all out of budget.'
    end

    it 'joins wrapped values onto a single line, preserving the indentation whitespace' do
      expect(configuration['meta data' => 'description']).to eq "This is a tediously long description of the Lonely Planet  programming test that you are taking. Tedious isn't the right word, but  it's the first word that comes to mind."
    end

    it 'raises a KeyError when looking up config values improperly' do
      expect { configuration['hi'] }.to raise_error KeyError
      expect { configuration[nil] }.to raise_error KeyError
      expect { configuration[foo: nil] }.to raise_error KeyError
    end
  end

  describe '#[]=' do
    it 'stores new values for retrieval' do
      configuration[planet: 'name'] = 'lonely'
      expect(configuration[planet: 'name']).to eq 'lonely'
    end

    it 'updates the configuration file on disk after each write' do
      configuration[planet: 'popularity'] = 'max!'
      reloaded_configuration = described_class.new tempfile_path
      expect(reloaded_configuration[planet: 'popularity']).to eq 'max!'
    end

    it 'converts numeric values to strings' do
      configuration[constants: 'pi'] = 3.14159
      expect(configuration[constants: 'pi']).to eq "3.14159"
      reloaded_configuration = described_class.new tempfile_path
      expect(reloaded_configuration[constants: 'pi']).to eq "3.14159"
    end

    it 'raises a KeyError when looking up config values improperly' do
      expect { configuration['hi'] = 1 }.to raise_error KeyError
      expect { configuration[nil] = "ok" }.to raise_error KeyError
      expect { configuration[foo: nil] = 1.2 }.to raise_error KeyError
    end
  end
end
