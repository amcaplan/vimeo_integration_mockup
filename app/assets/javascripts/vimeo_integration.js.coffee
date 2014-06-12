# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


verbalizeIt =
  dataContainer:
    tasks: []
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
        "<option value=\"#{languageCode}\">#{languageName}</option>"
      langsArray.join("\n")

    login: (notice="", signupErrors={}, email="", password="")->
      "<div id=\"captions_listing\" class=\"form_content\">
            <h3>Sign in to Continue</h3>
            <hr>
            <div class=\"row-fluid\">
                <div class=\"span6\">
                    <p>
                      New to VerbalizeIt?<br>
                      Fill in your email and a password, and click the button
                      to create a new account!
                    </p>
                    <p>
                        <label for=\"verbalizeit-email\">Email</label>
                        <input class=\"input bg-light-grey appendb20\" id=\"verbalizeit-email\" size=\"30\" type=\"email\" value=\"#{email}\">
                        #{if signupErrors.email
                            "<div class=\"error_message\">
                              Email #{signupErrors.email}
                            </div>"
                          else
                            ""
                        }
                    </p>
                    <br>
                    <p class=\"psm\">
                        <label for=\"verbalizeit-password\">Password</label>
                        <input class=\"input bg-light-grey appendb0\" id=\"verbalizeit-password\" size=\"30\" type=\"password\" value=\"#{password}\">
                        #{if signupErrors.password
                            "<div class=\"error_message\">
                              Password #{signupErrors.password}
                            </div>"
                          else
                            ""
                        }
                    </p>
                </div>
                <br>
            </div>

            <div class=\"verbalizeit-login-buttons\">
              <div class=\"btn verbalizeit-button signin-submit disabled\" id=\"verbalizeit-signin\">Sign in to VerbalizeIt</div>
              <div class=\"btn verbalizeit-button signin-submit disabled\" id=\"verbalizeit-create-account\">Create a New Account</div>
            </div>

            <div id=\"verbalizeit-notice\" class=\"error_message\">
              #{notice || ""}
            </div>
        </div>"

    languageChoice: ->
      "<h3>STEP 1: Choose Languages</h3>
      <hr>
      What language is this video?
      <br>
      <select id=\"verbalizeit-choose-from-language\">" +
        verbalizeIt.templates.languagesAsOptions() +
      "</select>
      <br>
      <br>
      <div id=\"verbalizeit-language-options\"></div>"
    
    translationOptions: (languageChoice)->
      template = if languageChoice is "en"
        "What language would you like captions in?
        <br>
        <select id=\"verbalizeit-choose-to-language\">" +
          verbalizeIt.templates.languagesAsOptions() +
        "</select>"
      else
        "Non-English languages can only be translated to English.
        <select class=\"hide\" id=\"verbalizeit-choose-to-language\">
          <option value=\"en\" selected></option>
        </select>"

      template + "<br><br>
        <div class=\"btn signin-submit\" id=\"verbalizeit-choose-language\">Get Quote</div>
        <div class=\"btn signin-submit\" id=\"verbalizeit-display-dashboard\">Return to Dashboard</div>"

    reviewOrder: (task)->
      if task.fromLanguage is task.toLanguage
        action = "Generating #{@languageCodeToName task.toLanguage} subtitles for this video"
      else
        action = "Translating this video from #{@languageCodeToName task.fromLanguage}" +
          " to #{@languageCodeToName task.toLanguage}"

      "<h3>STEP 2: Confirm Order</h3>
      <hr>
      #{action} will cost $#{task.cost.toFixed(2)}. Would you like to proceed?
      <br>
      <br>
      <div class=\"btn signin-submit\" id=\"verbalizeit-submit-task\">Accept</div>
      <div class=\"btn signin-submit\" id=\"verbalizeit-reject-task\">Go Back</div>"

    dashboard: (notice="")->
      tasks = verbalizeIt.dataContainer.tasks

      viewTemplate = $ "
          <div id=\"captions_listing\" class=\"form_content\">
              <h3>Your Orders</h3>
              <hr>
          
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
                #{notice}
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
                  "<a href=\"#\" class=\"verbalizeit-download-link\" data-task-id=\"#{task.id}\"
                    download=\"#{task.source_language}_to_#{task.target_language}.srt\">Download File</a>"
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

    verbalizeItWrapper: ->
      $("#verbalizeit-wrapper")

    toggleUploadOptions: ->
      if @uploadCaptionInput().is ":checked"
        @uploadCaptionForm().removeClass "hide"
        @verbalizeItWrapper().addClass "hide"
      else if @verbalizeItCaptionInput().is ":checked"
        @verbalizeItWrapper().removeClass "hide"
        @uploadCaptionForm().addClass "hide"

  loginHandler:
    loginProcess: ->
      @getInfo(@login)

    signupProcess: ->
      @getInfo(@signup)

    getInfo: (action)->
      $(".verbalizeit-button").addClass "disabled"
      $("#verbalizeit-caption-form").find(".error_message").text("")
      email = $("#verbalizeit-email").val()
      password = $("#verbalizeit-password").val()
      action(email, password).fail ->
        $(".verbalizeit-button").removeClass "disabled"

    login: (email, password)->
      $.post("https://stagingapi.verbalizeit.com/api/customers/login",
        {email: email, password: password})
      .done (response)->
        verbalizeIt.loginHandler.loggedIn(response)
      .fail (response, textStatus, errorThrown)->
        errors = JSON.parse(response.responseText)
        $("#verbalizeit-notice").text(errors.error)

    signup: (email, password)->
      $.post("https://stagingapi.verbalizeit.com/api/customers/register",
        {customer: {email: email, password: password}})
      .done (response)->
        verbalizeIt.loginHandler.loggedIn(response, withoutAjax: true)
      .fail (response, textStatus, errorThrown)->
        errors = JSON.parse(response.responseText).errors
        signupErrors =
          email: if errors.email then errors.email[0] else ""
          password: if errors.password then errors.password[0] else ""
        $("#verbalizeit-caption-form").html verbalizeIt.templates.login(
          "", signupErrors, email, password)
          
    loggedIn: (response, options={})->
      $(".verbalizeit-login-buttons").text("Loading Your Existing Tasks...")
      customer = response.customer
      verbalizeIt.dataContainer.authToken = customer.auth_token
      if options.withoutAjax
        verbalizeIt.dashboardHandler.drawDashboardWithoutAjax()
      else
        verbalizeIt.dashboardHandler.drawDashboard()

  dashboardHandler:
    drawDashboardWithoutAjax: (message=null)->
      $("#verbalizeit-caption-form").html(
        verbalizeIt.templates.dashboard(message)
      )

    drawDashboard: (message=" ")->
      $.get "https://stagingapi.verbalizeit.com/tasks?auth_token=#{verbalizeIt.dataContainer.authToken}",
        (response)=>
          verbalizeIt.dataContainer.tasks = response
          @drawDashboardWithoutAjax message

  languageHandler:
    displayLanguages: ->
      $("#verbalizeit-caption-form").html(
        verbalizeIt.templates.languageChoice)
      $("#verbalizeit-choose-from-language").trigger("change")

    handleTaskSubmission: (fromLanguageCode, toLanguageCode)->
      videoID = verbalizeIt.dataContainer.videoID
      $.post "https://stagingapi.verbalizeit.com/tasks/vimeo",
        {
          auth_token: verbalizeIt.dataContainer.authToken,
          url: "http://vimeo.com/#{videoID}",
          source_language: fromLanguageCode,
          target_language: toLanguageCode
        }, (response)->
          task =
            id: response.task_id
            cost: response.cost
            fromLanguage: fromLanguageCode
            toLanguage: toLanguageCode
          
          verbalizeIt.taskHandler.displayTask(task)

  taskHandler:
    displayTask: (task)->
      $("#verbalizeit-caption-form").html(
        verbalizeIt.templates.reviewOrder(task))
      
      $("#verbalizeit-caption-form").off 'click.submitTask'
      $("#verbalizeit-caption-form").on 'click.submitTask', "#verbalizeit-submit-task", ->
        $("#verbalizeit-submit-task").addClass "disabled"
        $.ajax "https://stagingapi.verbalizeit.com/tasks/#{task.id}/start?auth_token=#{verbalizeIt.dataContainer.authToken}",
          type:
            'PUT'
          success: (submittedTask)->
            submitted = "Success! Your request will be processed within 24 hours."
            submittedTask.source_language = task.fromLanguage
            submittedTask.target_language = task.toLanguage
            verbalizeIt.dataContainer.tasks.push submittedTask
            verbalizeIt.dashboardHandler.drawDashboardWithoutAjax(submitted)

  binders:
    uploadToggles: ->
      $("#caption-options").on "change", "input[name=caption-option]", =>
        verbalizeIt.loginViewToggler.toggleUploadOptions()

    loginButtons: ->
      $("#verbalizeit-caption-form").on "click", "#verbalizeit-signin", =>
        verbalizeIt.loginHandler.loginProcess()
      $("#verbalizeit-caption-form").on "keyup", ->
        buttons = $(".verbalizeit-button")
        if $("#verbalizeit-email").val() && $("#verbalizeit-password").val()
          buttons.removeClass "disabled"
        else
          buttons.addClass "disabled"
      $("#verbalizeit-caption-form").on "click", "#verbalizeit-create-account", =>
        verbalizeIt.loginHandler.signupProcess()
      $("#verbalizeit-caption-form").on "keypress", "#captions_listing", (e)->
        code = e.keyCode || e.which;
        if code == 13 then e.preventDefault()

    addTaskButton: ->
      $("#verbalizeit-caption-form").on "click", "#verbalizeit-add-task", ->
        verbalizeIt.languageHandler.displayLanguages()

    refreshDashboardButton: ->
      $("#verbalizeit-caption-form").on "click", "#verbalizeit-dashboard-refresh", ->
        @.addClass "disabled"
        verbalizeIt.dashboardHandler.drawDashboard()

    displayDashboardButton: ->
      $("#verbalizeit-caption-form").on "click", "#verbalizeit-display-dashboard", ->
        verbalizeIt.dashboardHandler.drawDashboardWithoutAjax()        

    selectFromLanguage: ->
      $("#verbalizeit-caption-form").on "change", "#verbalizeit-choose-from-language", ->
        $("#verbalizeit-language-options").html(
          verbalizeIt.templates.translationOptions $("#verbalizeit-choose-from-language").val())

    submitTaskButton: ->
      $("#verbalizeit-caption-form").on "click", "#verbalizeit-choose-language", ->
        $("#verbalizeit-choose-language").addClass "disabled"
        fromLanguageCode = $("#verbalizeit-choose-from-language").val()
        toLanguageCode = $("#verbalizeit-choose-to-language").val()
        verbalizeIt.languageHandler.handleTaskSubmission(
          fromLanguageCode, toLanguageCode)

    rejectTask: ->
      $("#verbalizeit-caption-form").on "click.rejectTask", "#verbalizeit-reject-task", ->
        verbalizeIt.languageHandler.displayLanguages()

    downloadFileLink: ->
      $("#verbalizeit-caption-form").on "click", ".verbalizeit-download-link", (e)->
        e.preventDefault()
        taskID = $(@).data("task-id")
        $.ajax
          url: "https://stagingapi.verbalizeit.com/tasks/#{taskID}?auth_token=#{verbalizeIt.dataContainer.authToken}"
          async: false
          success:  (response)->
            window.open(response.completed_file, "_blank")
          error: ->
            $("#verbalizeit-caption-form").find()

  getLanguages: ->
    $.get "https://stagingapi.verbalizeit.com/api/languages", (data)->
      $.each data.languages, (index, language)->
        verbalizeIt.dataContainer.languages[language.language_code] = language.name

  initialize: ->
    $.each @binders, (index, binder)->
      binder()
    @getLanguages()
    @dataContainer.videoID = $('link[rel=canonical]').attr('href').split('/')[1]
    $("#verbalizeit-caption-form").html(verbalizeIt.templates.login)

$(document).ready ->
  verbalizeIt.initialize()