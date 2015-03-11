class JenkinsJobPresenter < SimpleDelegator

  attr_reader :jenkins_job

  def initialize(jenkins_job, template)
    super(template)
    @jenkins_job = jenkins_job
  end


  def job_id
    jenkins_job.name.downcase.gsub(' ', '_')
  end


  def job_info
    s = ''
    s << content_tag(:h3, link_to(jenkins_job.name, jenkins_job.url, target: 'about_blank'))
    s << render_job_description unless jenkins_job.project.jenkins_setting.show_compact?
    s.html_safe
  end


  def latest_build_infos
    content_tag(:span, link_to_jenkins_job(jenkins_job), class: 'label label-info') +
    content_tag(:em, latest_build_date)
  end


  def job_state
    s = ''
    s << content_tag(:span, link_to_console_output, class: "label label-#{state_to_css_class(jenkins_job.state)}")
    s << content_tag(:span, '', class: 'icon icon-running') if jenkins_job.state == 'running'
    s.html_safe
  end


  def latest_build_duration
    Time.at(jenkins_job.latest_build_duration/1000).strftime "%M:%S" rescue "00:00"
  end


  def latest_changesets
    changesets = jenkins_job.builds.last.changesets rescue []
    return '' if changesets.empty?
    content_tag(:ul) do
      render_changesets_list(changesets)
    end
  end


  def job_history
    link_to_history
  end


  def job_actions
    s = ''
    s << link_to_build if User.current.allowed_to?(:build_jenkins_jobs, jenkins_job.project)
    s << link_to_refresh
    s.html_safe
  end


  private


    def render_job_description
      s = ''
      s << jenkins_job.description
      s << render_health_report if jenkins_job.health_report.any?
      s
    end


    def render_health_report
      content_tag(:ul, render_report_list)
    end


    def render_report_list
      s = ''
      jenkins_job.health_report.each do |health_report|
        s << content_tag(:li, "#{health_report['description']} #{weather_icon(health_report)}".html_safe)
      end
      s.html_safe
    end


    def latest_build_date
      " (#{format_time(jenkins_job.latest_build_date)})"
    end


    def link_to_console_output
      url = jenkins_job.latest_build_number == 0 ? 'javascript:void(0);' : console_jenkins_job_path(jenkins_job.project, jenkins_job)
      link_to state_to_label(jenkins_job.state), url, title: l(:label_see_console_output), class: 'modal-box-close-only'
    end


    def link_to_build
      link_to fa_icon('fa-gears'), build_jenkins_job_path(jenkins_job.project, jenkins_job), title: l(:label_build_now), remote: true
    end


    def link_to_refresh
      link_to fa_icon('fa-refresh'), refresh_jenkins_job_path(jenkins_job.project, jenkins_job), title: l(:label_refresh_builds), remote: true
    end


    def link_to_history
      link_to fa_icon('fa-history'), history_jenkins_job_path(jenkins_job.project, jenkins_job), title: l(:label_see_history), class: 'modal-box-close-only'
    end


    def fa_icon(icon)
      content_tag(:i, '', class: "fa fa-lg #{icon}")
    end


    def weather_icon(health_report)
      image_tag(plugin_asset_link('redmine_jenkins', health_report['iconUrl']), alt: health_report['iconUrl'], style: 'display: inline-block; margin-top: 5px;')
    end


    def render_changesets_list(changesets)
      changesets.each do |changeset|
        content_tag(:li, content_for_changeset(changeset))
      end
    end


    def content_for_changeset(changeset)
      content = ''
      content << changeset.comment
      content << link_to("##{changeset.revision[0..10]}", changeset_url(changeset)) unless jenkins_job.repository.nil?
      content
    end


    def changeset_url(changeset)
      { controller: 'repositories', action: 'revision', id: jenkins_job.project, repository_id: jenkins_job.repository.identifier_param, rev: changeset.revision }
    end

end
