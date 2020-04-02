require 'sfctl/commands/time/providers/set'

RSpec.describe Sfctl::Commands::Time::Providers::Set, type: :unit do
  let(:link_config_file) { '.sflink' }
  let(:output) { StringIO.new }
  let(:options) do
    { 'no-color' => true }
  end
  let(:toggl_provider) { 'toggl' }

  before do
    stub_const('Sfctl::Command::LINK_CONFIG_PATH', tmp_path(link_config_file))
  end

  it 'should shown an error if .sflink is not initialized' do
    described_class.new(options).execute(output: output)

    expect(output.string).to include 'Please initialize time before continue.'
  end

  it 'should ask for replace if provider alredy defined' do
    config_path = fixtures_path(link_config_file)
    ::FileUtils.cp(config_path, tmp_path(link_config_file))
    expect(File.file?(tmp_path(link_config_file))).to be_truthy

    expect_any_instance_of(TTY::Prompt).to receive(:select).and_return(toggl_provider)
    expect_any_instance_of(TTY::Prompt).to receive(:yes?).with('Do you want to replace it?').and_return(false)

    described_class.new(options).execute(output: output)

    expect(File.read(tmp_path(link_config_file))).to include toggl_provider
  end

  it 'should set a new toggl provider' do
    access_token = 'test_access_token'
    workspace = 'test_workspace'

    ::FileUtils.touch tmp_path(link_config_file)

    expect_any_instance_of(TTY::Prompt).to receive(:select).and_return(toggl_provider)

    expect_any_instance_of(TTY::Prompt).not_to receive(:yes?).with('Do you want to replace it?')

    expect_any_instance_of(TTY::Prompt).to receive(:ask)
      .with('Your access token at [toggl]:', required: true)
      .and_return(access_token)

    expect_any_instance_of(TTY::Prompt).to receive(:ask)
      .with('Your workspace at [toggl]:', required: true)
      .and_return(workspace)

    expect_any_instance_of(TTY::Prompt).to receive(:yes?).with('Is that information correct?').and_return(true)

    described_class.new(options).execute(output: output)

    expect(output.string).to include 'Everything saved.'

    expect(File.file?(tmp_path(link_config_file))).to be_truthy
    file_data = File.read(tmp_path(link_config_file))
    expect(file_data).to include toggl_provider
    expect(file_data).to include access_token
    expect(file_data).to include workspace
  end
end
