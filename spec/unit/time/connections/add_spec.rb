require 'tty-prompt'
require 'sfctl/commands/time/connections/add'

RSpec.describe Sfctl::Commands::Time::Connections::Add, type: :unit do
  let(:config_file) { '.sfctl' }
  let(:config_path) { fixtures_path(config_file) }
  let(:link_config_file) { '.sflink' }
  let(:link_config_path) { fixtures_path(link_config_file) }
  let(:output) { StringIO.new }
  let(:options) do
    {
      'no-color' => true,
      'starfish-host' => 'https://starfish.team'
    }
  end
  let(:toggl_provider) { 'toggl' }
  let(:assignments_url) { "#{options['starfish-host']}/api/v1/assignments" }
  let(:copy_config_files_to_tmp) do
    ::FileUtils.cp(config_path, tmp_path(config_file))
    ::FileUtils.cp(link_config_path, tmp_path(link_config_file))
  end
  let(:assignment_name) { 'Test assignment' }
  let(:assignments_response_body) do
    <<~HEREDOC
      {
        "assignments": [
          {
            "id": 1,
            "name": "#{assignment_name}",
            "service": "Engineering",
            "start_date": "2020-01-01",
            "end_date": "2020-05-15",
            "budget": 40,
            "unit": "hours"
          }
        ]
      }
    HEREDOC
  end

  before do
    stub_const('Sfctl::Command::CONFIG_PATH', tmp_path(config_file))
    stub_const('Sfctl::Command::LINK_CONFIG_PATH', tmp_path(link_config_file))
  end

  it 'should shown an error if .sfctl is not initialized' do
    ::FileUtils.cp(link_config_path, tmp_path(link_config_file))

    described_class.new(options).execute(output: output)

    expect(output.string).to include 'Please authentificate before continue.'
  end

  it 'should shown an error if .sflink is not initialized' do
    ::FileUtils.cp(config_path, tmp_path(config_file))

    described_class.new(options).execute(output: output)

    expect(output.string).to include 'Please initialize time before continue.'
  end

  it 'should return an error if assignments could not be fetched' do
    copy_config_files_to_tmp

    stub_request(:get, assignments_url).to_return(body: '{"error":"forbidden"}', status: 403)

    described_class.new(options).execute(output: output)

    expect(output.string).to include 'Something went wrong. Unable to fetch assignments'
  end

  it 'should return a message that all assignments are already added' do
    copy_config_files_to_tmp

    stub_request(:get, assignments_url).to_return(body: assignments_response_body, status: 200)

    described_class.new(options).execute(output: output)

    expect(output.string).to include 'All assignments already added.'
  end

  it 'should add new connection' do
    copy_config_files_to_tmp

    assignment_name = 'Test assignment 2'
    assignments_response_body = <<~HEREDOC
      {
        "assignments": [
          {
            "id": 1,
            "name": "#{assignment_name}",
            "service": "Engineering",
            "start_date": "2020-01-01",
            "end_date": "2020-05-15",
            "budget": 40,
            "unit": "hours"
          }
        ]
      }
    HEREDOC

    stub_request(:get, assignments_url).to_return(body: assignments_response_body, status: 200)

    expect_any_instance_of(TTY::Prompt).to receive(:select).with('Select provider:', [toggl_provider])
      .and_return(toggl_provider)

    expect_any_instance_of(TTY::Prompt).to receive(:select).with('Select assignment:').and_return(assignment_name)

    workspace_id = 'test_workspace_id'
    expect_any_instance_of(TTY::Prompt).to receive(:ask)
      .with('Workspace ID (required):', required: true)
      .and_return(workspace_id)

    project_ids = 'project_id1, project_id2'
    expect_any_instance_of(TTY::Prompt).to receive(:ask)
      .with('Project IDs  (required / comma separated):', required: true)
      .and_return(project_ids)

    task_ids = 'task_ids1, task_ids2, task_ids3, task_ids4'
    expect_any_instance_of(TTY::Prompt).to receive(:ask)
      .with('Task IDs     (optional / comma separated):')
      .and_return(task_ids)

    billable = 'yes'
    expect_any_instance_of(TTY::Prompt).to receive(:select)
      .with('Billable?    (required)', %w[yes no both])
      .and_return(billable)

    rounding = 'on'
    expect_any_instance_of(TTY::Prompt).to receive(:select)
      .with('Rounding?    (required)', %w[on off])
      .and_return(rounding)

    described_class.new(options).execute(output: output)

    expect(output.string).to include 'Connection successfully added.'

    file_data = File.read(tmp_path(link_config_file))
    expect(file_data).to include 'connections:'
    expect(file_data).to include assignment_name
    expect(file_data).to include toggl_provider
    expect(file_data).to include workspace_id
    expect(file_data).to include project_ids
    expect(file_data).to include task_ids
    expect(file_data).to include billable
    expect(file_data).to include rounding
  end
end