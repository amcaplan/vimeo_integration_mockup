# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


verbalizeIt =
  dataContainer:
    tasks: []

  templates:
    languageChoice: (languageOptions)->
      "This video is in:
      <br>
      <select id=\"verbalizeIt-choose-from-language\">" +
         languageOptions +
      "</select>
      <br>
      <br>
      Captions should be in:
      <br>
      <select id=\"verbalizeIt-choose-to-language\">" +
        languageOptions +
      "</select>
      <br>
      <br>
      <div class=\"btn signin-submit\" id=\"verbalizeit-choose-language\">Continue</div>"

    reviewOrder: (job)->
      if job.fromLanguage is job.toLanguage
        action = "Generating #{job.toLanguage} subtitles for this video"
      else
        action = "Translating this video from #{job.fromLanguage} to #{job.toLanguage}"

      action + " will cost $#{job.cost}. " +
        " Would you like to proceed? <div class=\"btn signin-submit\" " +
        "id=\"verbalizeit-submit-task\">Accept</div>"

    submitted: (job)->
      "Success! Your request will be processed within 24 hours."

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
    getInfo: (action)->
      email = $("#verbalizeit-email").val()
      password = $("#verbalizeit-password").val()
      action(email, password)

    loginProcess: ->
      @getInfo(@login)

    signupProcess: ->
      @getInfo(@signup)

    login: (email, password)->
      $.post "https://stagingapi.verbalizeit.com/api/customers/login",
        {email: email, password: password}, (response)=>
          customer = response.customer
          verbalizeIt.dataContainer.authToken = customer.auth_token
          verbalizeIt.languageHandler.displayLanguages()
          verbalizeIt.languageHandler.enableSubmitButton()

    signup: (email, password)->
      $.post "https://stagingapi.verbalizeit.com/api/customers/register",
        {customer: {email: email, password: password}}, (response)=>
          customer = response.customer
          verbalizeIt.dataContainer.authToken = customer.auth_token
          verbalizeIt.languageHandler.displayLanguages()
          verbalizeIt.languageHandler.enableSubmitButton()      

  languageHandler:
    displayLanguages: ->
      $.get "https://stagingapi.verbalizeit.com/api/languages", (response)=>
        languageOptions = @parseAsOptions(response.languages)

        $("#verbalizeit-caption-form").html(
          verbalizeIt.templates.languageChoice(languageOptions))

    parseAsOptions: (languages)->
      $.map(languages, (language,index)->
        "<option value=\"#{language.language_code}\"" +
        "data-language-name=#{language.name}>" +
        language.name + "</option>"
      ).join()

    handleJobSubmission: (fromLanguageCode, toLanguageCode, fromLanguage, toLanguage)->
      videoID = $('link[rel=canonical]').attr('href').split('/')[1]
      $.post "https://stagingapi.verbalizeit.com/tasks/vimeo",
        {
          auth_token: verbalizeIt.dataContainer.authToken,
          url: "http://vimeo.com/#{videoID}",
          source_language: fromLanguageCode,
          target_language: toLanguageCode
        }, (response)->
          job = {
            id: response.task_id,
            cost: response.cost,
            fromLanguage: fromLanguage,
            toLanguage: toLanguage
          }
          verbalizeIt.jobHandler.displayJob(job)

    enableSubmitButton: ->
      $("#verbalizeit-caption-form").on "click", "#verbalizeit-choose-language", =>
        fromLanguageCode = $("#verbalizeIt-choose-from-language").val()
        fromLanguage = $("option[value=#{fromLanguageCode}").data("language-name")
        toLanguageCode = $("#verbalizeIt-choose-to-language").val()
        toLanguage = $("option[value=#{toLanguageCode}").data("language-name")
        @handleJobSubmission(fromLanguageCode, toLanguageCode, fromLanguage, toLanguage)

  jobHandler:
    displayJob: (job)->
      $("#verbalizeit-caption-form").html(
        verbalizeIt.templates.reviewOrder(job))
      
      $("#verbalizeit-caption-form").on 'click', "#verbalizeit-submit-task", ->
        $.ajax "https://stagingapi.verbalizeit.com/tasks/#{job.id}/start?auth_token=#{verbalizeIt.dataContainer.authToken}",
          success: ->
            $("#verbalizeit-caption-form").html(verbalizeIt.templates.submitted(job))
          type:
            'PUT'


  bindUploadToggles: ->
    $('input[name=caption-option]').change =>
      @loginViewToggler.toggleUploadOptions()

  bindLoginButtons: ->
    $("#verbalizeit-signin").click =>
      @loginHandler.loginProcess()
    $("#verbalizeit-create-account").click =>
      @loginHandler.signupProcess()
    $("#captions_listing").keypress (e)->
      code = e.keyCode || e.which;
      if code == 13 then e.preventDefault()

  initialize: ->
    @bindUploadToggles()
    @bindLoginButtons()

$(document).ready ->
  verbalizeIt.initialize()