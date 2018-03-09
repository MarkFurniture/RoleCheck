require 'sqlite3'
require 'discordrb'

class RoleCheck
	attr_reader :bot

	def initialize
		configure
		init_db

		@bot = Discordrb::Commands::CommandBot.new token: "NDIxNDAyNTQwMTQ4NjU0MDkx.DYMuGQ.plYHt1GsSbm609wfo72q6mqKzPI", client_id: 421402540148654091, prefix: '.'
		@bot.name = "RoleCheck"

		init_commands
	end

	def configure
		@config = {
			:db_name => "rolecheck.db",
			:managed_roles => ["Tank", "Healer", "DPS", "Caster", "Ranged", "Melee", "Adamantoise", "Balmung", "Cactuar", "Coeurl", "Faerie", "Gilgamesh", "Goblin", "Jenova", "Mateus", "Sargatanas", "Siren", "Zalera", "AllChat", "Pervy", "Crafter"]
			# :managed_roles => ["tank", "healer", "dps", "caster", "ranged", "melee", "adamantoise", "balmung", "cactuar", "coeurl", "faerie", "gilgamesh", "goblin", "jenova", "mateus", "sargatanas", "siren", "zalera", "allchat", "pervy", "crafter"]
		}
	end

	def init_db
		db = get_db_connection

		# check if the required tables exist
		tables = db.execute <<-SQL
			SELECT name
			FROM sqlite_master
			WHERE type='table';
		SQL

		tables.flatten!
		
		# add tables if necessary
		if !tables.include? "servers"
			puts "Table \"servers\" not found, adding."

			db.execute <<-SQL
				create table servers (
					id int primary key,
					server_name varchar(50),
					created datetime,
					modified datetime
				);
			SQL
		end

		if !tables.include? "roles"
			puts "Table \"roles\" not found, adding."

			db.execute <<-SQL
				create table roles (
					id int primary key,
					server_id int,
					role_name varchar(100),
					created datetime,
					modified datetime
				);
			SQL
		end
	end


	def get_db_connection
		SQLite3::Database.new @config[:db_name]
	end

	def server_exists?(server_name)
		db = get_db_connection

		server = db.execute("
			select server_id
			from servers
			where server_name = ?", server_name)

		# if ()

		db.close
		p server
	end

	def init_commands
		# => admin commands
		@bot.command :addmanagedroles do |event, *args|
			server_exists? event.server.name

			server_roles = server_role_names(event)
			roles_to_add = []


			# args.each do |role|
			# 	if server_roles.include? role.downcase
			# 		roles_to_add << 
			# 	end
			# end
		end

		@bot.command :removemanagedroles do |event, *args|
		end

		@bot.command :managedroles do |event|
			if event.user.permission? :manage_roles
				event.respond "Roles managed by this bot: #{@config[:managed_roles].join ", "}"
				event.respond "To modify roles, use #{@config[:prefix]}addmanagedrole/#{@config[:prefix]}removemanagedrole"
			end
		end

		# => user commands

		# => !iam
		@bot.command :iam do |event, *args|
			modify_user_roles event, args, true
		end

		# => !iamnot
		@bot.command :iamnot do |event, *args|
			modify_user_roles event, args, false

			nil
		end
	end

	def modify_user_roles(event, args, add)
		# remove extra whitespace and parse comma delimitation to allow multiple roles in one request
		args_roles = args.join(" ").split(",").map(&:strip)
		changed_roles = []

		# separate actual roles from typoes/nonexistant roles
		roles_good, ignored = args_roles.partition do |role|
			server_role_names(event).include?(role) && !@config[:managed_roles].select { |r| r.downcase == role }.empty?
		end

		# act on each actual role
		roles_good.each do |ur|
			role = server_role event, ur

			if add
				# add roles
				if (!event.user.roles.include? role)
					changed_roles << role.name
					event.user.add_role(role)
				end
			else
				# remove roles
				if (event.user.roles.include? role)
					changed_roles << role.name
					event.user.remove_role(role)
				end
			end

		end

		if (changed_roles.length > 0)
			event.respond "You are #{add ? "now" : "no longer"} #{changed_roles.join ", "}."
		end

		if (ignored.length > 0)
			event.respond "#{ignored.join ","} #{ignored.length > 1 ? "are not roles." : "is not a role"}."
		end

		nil
	end

	# returns array of role names
	def server_role_names(event)
		event.server.roles.map { |server_role| server_role.name.downcase }
	end

	# returns a Role object by name
	def server_role(event, role_name)
		event.server.roles.select { |role| role.name.downcase == role_name.downcase }.first
	end

	def join(invite)
		@bot.join invite
	end

	def run
		@bot.run
	end

	def about
	end
end

if __FILE__ == $0
	bot = RoleCheck.new
	bot.run
end