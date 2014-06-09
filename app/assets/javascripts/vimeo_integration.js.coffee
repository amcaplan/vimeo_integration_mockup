# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


verbalizeIt =
  dataContainer:
    languages: {}

  templates:
    languageCodeToName: (code)->
      verbalizeIt.dataContainer.languages[code]

    statusExplanation: (status)->
      explanations =
        preview: "Waiting for confirmation"
        preprocess: "Initializing Processing"
        open: "Waiting for Translation"
        in_progress: "Translator is Working"
        in_review: "Translator is Reviewing"
        admin_review: "Administrators are Reviewing"
        complete: "Complete"
      explanations[status]

    languagesAsOptions: ->
      languages = verbalizeIt.dataContainer.languages
      langsArray = for languageCode, languageName of languages
        "<option value=\"#{languageCode}\" data-language-name=#{languageName}>" +
          languageName + "</option>"
      langsArray.join("\n")

    languageChoice: ->
      "This video is in:
      <br>
      <select id=\"verbalizeIt-choose-from-language\">" +
        verbalizeIt.templates.languagesAsOptions() +
      "</select>
      <br>
      <br>
      Captions should be in:
      <br>
      <select id=\"verbalizeIt-choose-to-language\">" +
        verbalizeIt.templates.languagesAsOptions() +
      "</select>
      <br>
      <br>
      <div class=\"btn signin-submit\" id=\"verbalizeit-choose-language\">Continue</div>"

    reviewOrder: (task)->
      if task.fromLanguage is task.toLanguage
        action = "Generating #{task.toLanguage} subtitles for this video"
      else
        action = "Translating this video from #{task.fromLanguage} to #{task.toLanguage}"

      action + " will cost $#{task.cost}. " +
        " Would you like to proceed? <div class=\"btn signin-submit\" " +
        "id=\"verbalizeit-submit-task\">Accept</div>"

    dashboard: (notice=null)->
      tasks = verbalizeIt.dataContainer.tasks

      viewTemplate = $ "<div id=\"captions_listing\" class=\"form_content\">

          <div class=\"caption_row header js-caption_list_header \">
              <div class=\"caption_col lang\">Languages</div>
              <div class=\"caption_col status\">Status</div>
              <div class=\"caption_col file\">Download Link</div>
          </div>

          <div id=\"verbalizeit-tasks\" class=\"caption_row\">
          </div>

          <br>

          <div class=\"btn signin-submit\" id=\"verbalizeit-add-task\">Order a translation</div>
          <div class=\"btn signin-submit\" id=\"verbalizeit-dashboard-refresh\">Refresh data</div>
          <br>

          <div id=\"verbalizeit-notice\" class=\"error_message\">
            #{notice || ""}
          </div>
      </div>"

      if tasks.length is 0
        viewTemplate.find("#verbalizeit-tasks").append "
          You currently have no translations ordered for this video.
        "
      else
        $.each tasks, (index, task)=>
          if task.status != "preview"
            viewTemplate.find("#verbalizeit-tasks").append "
              <div class=\"caption_col lang\">
                #{@languageCodeToName task.source_language} -> #{@languageCodeToName task.target_language}
              </div>
              <div class=\"caption_col status\">
                #{@statusExplanation task.status}
              </div>
              <div class=\"caption_col file\">
                #{if task.status == "complete"
                  "<a href=\"#\" class=\"verbalizeit-download-link\" data-task-id=\"#{task.id}\">Download File</a>"
                else
                  "<em>pending</em>"
              }
              </div>
            "

      viewTemplate.html()

  loginViewToggler:
    uploadCaptionInput: ->
      $("#upload-caption-radio")

    uploadCaptionForm: ->
      $("#upload-caption-form")

    verbalizeItCaptionInput: ->
      $("#verbalizeit-caption-radio")

    verbalizeItCaptionForm: ->
      $("#verbalizeit-caption-form")

    toggleUploadOptions: ->
      if @uploadCaptionInput().is(":checked")
        @uploadCaptionForm().removeClass("hide")
        @verbalizeItCaptionForm().addClass("hide")
      else if @verbalizeItCaptionInput().is(":checked")
        @verbalizeItCaptionForm().removeClass("hide")
        @uploadCaptionForm().addClass("hide")

  loginHandler:
    loginProcess: ->
      @getInfo(@login)

    signupProcess: ->
      @getInfo(@signup)

    getInfo: (action)->
      email = $("#verbalizeit-email").val()
      password = $("#verbalizeit-password").val()
      action(email, password)

    login: (email, password)->
      $.post "https://stagingapi.verbalizeit.com/api/customers/login",
        {email: email, password: password}, (response)->
          verbalizeIt.loginHandler.loggedIn(response)

    signup: (email, password)->
      $.post "https://stagingapi.verbalizeit.com/api/customers/register",
        {customer: {email: email, password: password}}, (response)->
          verbalizeIt.loginHandler.loggedIn(response)
          
    loggedIn: (response)->
      customer = response.customer
      verbalizeIt.dataContainer.authToken = customer.auth_token
      verbalizeIt.dashboardHandler.drawDashboard()

  dashboardHandler:
    drawDashboard: (message=null)->
      $.get "https://stagingapi.verbalizeit.com/tasks?auth_token=#{verbalizeIt.dataContainer.authToken}",
        (response)=>
          verbalizeIt.dataContainer.tasks = response
          $("#verbalizeit-caption-form").html(
            verbalizeIt.templates.dashboard(message)
          )

  languageHandler:
    displayLanguages: ->
      $("#verbalizeit-caption-form").html(
        verbalizeIt.templates.languageChoice)

    handleTaskSubmission: (fromLanguageCode, toLanguageCode, fromLanguage, toLanguage)->
      videoID = $('link[rel=canonical]').attr('href').split('/')[1]
      $.post "https://stagingapi.verbalizeit.com/tasks/vimeo",
        {
          auth_token: verbalizeIt.dataContainer.authToken,
          url: "http://vimeo.com/#{videoID}",
          source_language: fromLanguageCode,
          target_language: toLanguageCode
        }, (response)->
          task = {
            id: response.task_id,
            cost: response.cost,
            fromLanguage: fromLanguage,
            toLanguage: toLanguage
          }
          verbalizeIt.taskHandler.displayTask(task)

  taskHandler:
    displayTask: (task)->
      $("#verbalizeit-caption-form").html(
        verbalizeIt.templates.reviewOrder(task))
      
      $("#verbalizeit-caption-form").off 'click.submitTask'
      $("#verbalizeit-caption-form").on 'click.submitTask', "#verbalizeit-submit-task", ->
        $.ajax "https://stagingapi.verbalizeit.com/tasks/#{task.id}/start?auth_token=#{verbalizeIt.dataContainer.authToken}",
          success: ->
            submitted = "Success! Your request will be processed within 24 hours."
            verbalizeIt.dashboardHandler.drawDashboard(submitted)
          type:
            'PUT'

  binders:
    uploadToggles: ->
      $('input[name=caption-option]').change =>
        verbalizeIt.loginViewToggler.toggleUploadOptions()

    loginButtons: ->
      $("#verbalizeit-signin").click =>
        verbalizeIt.loginHandler.loginProcess()
      $("#verbalizeit-create-account").click =>
        verbalizeIt.loginHandler.signupProcess()
      $("#captions_listing").keypress (e)->
        code = e.keyCode || e.which;
        if code == 13 then e.preventDefault()

    addTaskButton: ->
      $("#verbalizeit-caption-form").on "click", "#verbalizeit-add-task", ->
        verbalizeIt.languageHandler.displayLanguages()

    refreshDashboardButton: ->
      $("#verbalizeit-caption-form").on "click", "#verbalizeit-dashboard-refresh", ->
        @.addClass("disabled")
        verbalizeIt.dashboardHandler.drawDashboard()      

    submitTaskButton: ->
      $("#verbalizeit-caption-form").on "click", "#verbalizeit-choose-language", ->
        fromLanguageCode = $("#verbalizeIt-choose-from-language").val()
        fromLanguage = $("option[value=#{fromLanguageCode}").data("language-name")
        toLanguageCode = $("#verbalizeIt-choose-to-language").val()
        toLanguage = $("option[value=#{toLanguageCode}").data("language-name")
        verbalizeIt.languageHandler.handleTaskSubmission(
          fromLanguageCode, toLanguageCode, fromLanguage, toLanguage)

    downloadFileLink: ->
      $("#verbalizeit-caption-form").on "click", ".verbalizeit-download-link", ->
        taskID = $(@).data("task-id")
        $.get "https://stagingapi.verbalizeit.com/tasks/#{taskID}?auth_token=#{verbalizeIt.dataContainer.authToken}", (response)->
          window.open(response.completed_file, "_blank")

  getLanguages: ->
    $.get "https://stagingapi.verbalizeit.com/api/languages", (data)->
      $.each data.languages, (index, language)->
        verbalizeIt.dataContainer.languages[language.language_code] = language.name

  initialize: ->
    $.each @binders, (index, binder)->
      binder()
    @getLanguages()

$(document).ready ->
  verbalizeIt.initialize()