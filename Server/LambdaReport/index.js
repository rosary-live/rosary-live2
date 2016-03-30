console.log('Loading function');

// dependencies
var AWS = require('aws-sdk');
var util = require('util');
var moment = require('moment');
var config = require('./config.json');

// Get reference to AWS clients
var dynamodb = new AWS.DynamoDB();

function addSchedule(event, callback) {
	var now = moment().utc().format('X');

	// Add DDB record
	dynamodb.putItem({
		TableName: config.DDB_REPORT_TABLE,		
		Item: {
			bid: { S: event.bid },
			version: { N: event.version.toString() },
			created: { N: now },
			reporter: { S: event.reporter },
			reporter_name: { S: event.reporter_name },
			report: { S: event.report },

			language: { S: event.language },
			user: { S: event.user },
			name: { S: event.name },
			city: { S: event.city },
			state: { S: event.state },
			country: { S: event.country },
			lat: { S: event.lat },
			lon: { S: event.lon }
		},
		ReturnValues: 'NONE'
	}, function(err, data) {
		console.log(util.inspect(err, { showHidden: true, depth: 10 }));
		if(err) callback(err, null);
		else callback(null, data);
	});	
}

function sendReportEmail(email, event, fn) {
	var subject = 'Broadcast Report for ' + event.name + ' by ' + event.reporter_name;
	var verificationLink = config.VERIFICATION_PAGE + '?email=' + encodeURIComponent(email) + '&verify=' + token;
	ses.sendEmail({
		Source: config.EMAIL_SOURCE,
		Destination: {
			ToAddresses: [
				email
			]
		},
		Message: {
			Subject: {
				Data: subject
			},
			Body: {
				Html: {
					Data: '<html><head>'
					+ '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />'
					+ '<title>' + subject + '</title>'
					+ '</head><body>'
					+ 'Please <a href="' + verificationLink + '">click here to verify your email address</a> or copy & paste the following link in a browser:'
					+ '<br><br>'
					+ '<a href="' + verificationLink + '">' + verificationLink + '</a>'
					+ '</body></html>'
				}
			}
		}
	}, fn);
}

exports.handler = function(event, context) {
	console.log("event: " + util.inspect(event));

	addReport(event, function(err, result) {
		if(err) context.fail({success:false, message: 'Failed to add report.', error:err});
		else context.succeed({success:true});
	});
}
