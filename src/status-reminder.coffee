# Description
#   Remind users to give a daily status update
#
# Commands:
#   status reminder add user <username> - Add a user
#   status reminder remove user <username> - Remove a user
#   status reminder list users - List all users getting reminders and show stats
#   status reminder send reminders - Send reminders
#
# Notes:
#   You can use package hubot-cron-json to execute the send reminders task
#   at a certain time. Update conf/cron-tasks.json to set the time.
#
# Author:
#   nick warner

module.exports = (robot) ->
  robot.brain.data.status_reminder ||= {}
  robot.brain.data.status_reminder.users ||= []

  seconds_since_midnight = ->
    d = new Date()
    e = new Date(d)
    e - d.setHours(0,0,0,0)

  midnight_today = ->
    new Date().getTime() - seconds_since_midnight

  midnight_yesterday = ->
    midnight_today - 86400 # seconds per day

  time_was_yesterday = (time) ->
    time < midnight_today && time >= midnight_yesterday

  send_reminders = ->
    for user in robot.brain.data.status_reminder.users
      if user.last_status_date < midnight_today
        message = "Hey #{username}! Please update your daily status. Thanks!"
        robot.send {user: {name: user.username}}, message

  robot.respond /status reminder add user\s+(.*)?$/i, (msg) ->
    username = msg.match[1]
    user =
      streak: 0
      last_status_date: 0
      username: username
    robot.brain.data.status_reminder.users.push user
    msg.send "Added user: #{username}"

  robot.respond /status reminder remove user\s+(.*)?$/i, (msg) ->
    username = msg.match[1]
    users = robot.brain.data.status_reminder.users
    robot.brain.data.status_reminder.users = users.filter (user) ->
      user.username != username
    msg.send "Removed user: #{username}"

  robot.respond /status reminder list users/i, (msg) ->
    for user in robot.brain.data.status_reminder.users
      if user.last_status_date == 0
        date_str = "never :("
      else
        date_str = (new Date(user.last_status_date)).toLocaleDateString()
      msg.send "#{user.username} - Streak: #{user.streak} - Last update: #{date_str}"

  robot.respond /status reminder send reminders/i, ->
    send_reminders()

  robot.on /status reminder send reminders/i, ->
    send_reminders()

  robot.hear /^t:|^today:|^y:|^yesterday:/i, (msg) ->
    username = msg.message.user.name
    users = robot.brain.data.status_reminder.users
    index = users.map((user) -> user.username).indexOf(username)
    user = robot.brain.data.status_reminder.users[index]
    user.streak = time_was_yesterday(user.last_status_date) ? user.streak + 1 : 0
    user.last_status_date = new Date().getTime()
