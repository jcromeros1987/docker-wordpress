require 'rest-client'

namespace :notify do
  task :init do
    notifier = fetch(:slack_notifier, nil)

    if notifier.nil?
      notifier = SlackNotifier.new(branch: fetch(:branch), deploy_group: 'production')
      set(:slack_notifier, notifier)
   end

    on roles(:web) do
      revision = capture("test -r #{fetch(:deploy_to)}/current/REVISION && cat #{fetch(:deploy_to)}/current/REVISION; true")

      unless revision.nil?
        fetch(:slack_notifier).revision = revision
      end
    end
  end

  task :begin => :init do
    $deploy_started_at = Time.now.utc.to_i
    fetch(:slack_notifier).notify_begin
  end

  task :end => :init do
    $deploy_finished_at = Time.now.utc.to_i
    fetch(:slack_notifier).notify_end
  end
end

class SlackNotifier
  ENDPOINT = 'https://hooks.slack.com/services/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'

  attr_accessor :branch, :deploy_group, :revision

  def initialize(branch:, deploy_group:)
    @branch = branch
    @deploy_group = deploy_group
  end

  def notify_begin
    RestClient.post(ENDPOINT, payload(:begin))
  end

  def notify_end
    RestClient.post(ENDPOINT, payload(:end))
  end

  private

  def payload(state)
    {
      username: git_name,
      attachments: [
        {
          title: subject(state),
          color: deploy_color,
          unfurl_links: true,
          author_name: 'wordpress',
          text: "#{"=" * 80}\n #{commits}",
          mrkdwn_in: ['text'],
          fields: [
            { title: 'Branch', value: branch, short: true },
            { title: 'Deployer', value: git_name, short: true },
            { title: 'Environment', value: deploy_group, short: true },
            { title: 'Commits Count', value: commits_count, short: true }
          ]
        }
      ]
    }.to_json
  end

  def subject(state)
    ["[#{notify_action}]".upcase, "[#{state.to_s.upcase}]"].tap do |parts|
      if (duration = $deploy_finished_at.to_i - $deploy_finished_at.to_i) > 0
        parts << "[#{duration} seconds]"
      end
    end.join(' ')
  end

  def notify_action
    if deploy_group == branch
      deploy_group
    else
      "#{branch} to #{deploy_group}"
    end
  end

  def deploy_color
    @deploy_color ||= deploy_group == 'production' ? 'danger' : '#dddddd'
  end

  def git_name
    @git_name ||= `git config --get user.name`.strip || `whoami`
  end

  def commits_count
    @commits_count ||= commits.scan('https://github.com/wishpond-dev/wordpress/commit').count
  end

  def commits
    @commits ||=
      if revision.nil?
        'No commits'
      else
        format = '%an: %s %n https://github.com/wishpond-dev/wordpress/commit/%H %n%n'
        %x(git log #{revision}..origin/#{branch} --no-merges --format=format:"#{format}")
      end
  end
end
