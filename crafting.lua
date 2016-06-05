--[[

- fix problem where on server it opens 3 or more times for player
- replace e button with another key or chat command 'craft'
- Remove and add items from player
- Add filter to only send to 1 player
- Check which index is clicked on left menu thing to set it's information n shit
- lua starts it's index at 1 instead of 0 fuck lua
--]]

-- Fill in the database information below 
-- *****************************************************************
database = {}
database.host = "" -- Host/IP to connect to database
database.username = "" -- Username to connect to database
database.password = "" -- Password to connect to database
-- *****************************************************************

if SERVER then

	require("mysqloo")
	util.AddNetworkString( "returnCraftables" ) -- returns craftable list
	util.AddNetworkString( "getCraftables" ) -- asks server for craftable list
	util.AddNetworkString( "craftItem" ) -- asks server to craft item

	
	net.Receive( "getCraftables", function( len, ply )
	 getInformation()
	end)

	net.Receive( "craftItem", function( len, ply )
	 craftItem()
	end)

	function craftItem()
		-- Once again check if the player has the ammount of items necessary

		-- if yes give it to them

	end

	-- function gets the information from database and sends it to the client
	function getInformation()

		-- Connect to the database
		local db = mysqloo.connect( database.host, database.username, database.password, "DarkRP", 3306 )

		function db:onConnected()

		    print( "Database has connected!" )

		    local d = self:query( "SELECT * FROM `crafting_system`" )
		    
			function d:onSuccess( data )

		        print( "Query successful!" )
		        --PrintTable( data )
		        --print(data[1].wood)
		        

		        -- Send the data found back to the client 
		        net.Start( "returnCraftables" )
		 		net.WriteTable(data)
		 		net.Broadcast()

		    end

		    function d:onError( err, sql )

		        print( "Query errored!" )
		        print( "Query:", sql )
		        print( "Error:", err )

		    end

		    d:start()
		end

		function db:onConnectionFailed( err )

		    print( "Connection to database failed!" )
		    print( "Error:", err )
		end

		db:connect()

	end
end

if CLIENT then

	-- Recipe information
	--local itemDescription = "this is a test description"
	--local itemNameText = "test item name"
	--local metal = 0
	--local cloth = 0
	--local circuit = 0
	--local wood = 0
	--local plastic = 0
	--local glue = 0
	--local tape = 0
	--local nails = 0
	
	-- function displays the crafting menu with information retreieved from server
	function displayPanel ()

		-- Get the information from the database
		net.Start( "getCraftables" )
		net.SendToServer( Entity( 1 ) )

		-- Retrieved infrormation
		net.Receive( "returnCraftables", function( len, ply )
	 		items = net.ReadTable() -- Not sure if there is another way than making this global, I was unable to modify higher up variables from this scope


			local Crafting_Menu = vgui.Create("DFrame")
			Crafting_Menu:SetPos( ScrW()/2 - 75, ScrH()/2 - 50 )
			Crafting_Menu:SetSize( 600, 400 )
			Crafting_Menu:SetTitle( "Sentry Gaming Crafting System (Beta)" )
			Crafting_Menu:SetDraggable( false )
			Crafting_Menu:MakePopup()

			local list_recipes = vgui.Create( "DListView", Crafting_Menu )
			list_recipes:SetMultiSelect( false )
			list_recipes:AddColumn( "Craftables" )
			
			-- Add the items to the list
			for key in pairs(items) do
				list_recipes:AddLine(items[key].itemName)
			end
			
			list_recipes:SetSize(190, 358)
			list_recipes:SetPos(10, 32)

			local Panel_Information = vgui.Create( "DPanel", Crafting_Menu )
			Panel_Information:SetPos( 220, 32 ) -- Set the position of the panel
			Panel_Information:SetSize( 370, 358 ) -- Set the size of the panel
			
			local itemName = vgui.Create( "DLabel", Panel_Information )

			itemName:SetText( items[1].itemName ) -- Set the text of the label
			itemName:SizeToContents() 
			itemName:SetPos( 370/2 - 20, 10 ) -- Set the position of the label
			itemName:SetDark( 1 ) -- Set the colour of the text inside the label to a darker one

			local description = vgui.Create("DLabel",Panel_Information)

			description:SetText( items[1].itemDescription)
			description:SizeToContents()
			description:SetPos(10, 30)
			description:SetDark(1)

			local List	= vgui.Create( "DIconLayout", Panel_Information )
			List:SetSize( 355, 300 )
			List:SetPos( 10, 70 )
			List:SetSpaceY( 10 ) //Sets the space in between the panels on the X Axis by 5
			List:SetSpaceX( 5 ) //Sets the space in between the panels on the Y Axis by 5

			for i = 1, 8 do 
			local ListItem = List:Add( "DPanel" )
			ListItem:SetSize( 84, 50 )
			end

			local craft_button = vgui.Create( "DButton", Panel_Information )
			craft_button:SetPos( 370/2 - 60, 358 - 120 )
			craft_button:SetText( "Craft" )
			craft_button:SetSize( 120, 60 )
			craft_button.DoClick = function()
				craftItem()
			end

			-- Function that updates information whenever user selects another line
			function list_recipes:OnRowSelected(rowIndex, row)
				--print (rowIndex)
				itemName:SetText( items[rowIndex].itemName )
				description:SetText( items[rowIndex].itemDescription)

			end
		end)
	end

	-- Checks players items to avoid extra calls than triggers server asking to craft item
	function craftItem() 
		print ("crafting the item")
		-- Check if they have enough crafting materials to craft it (note this is just a quick insecure check to reduce possible server load, actual check is redone by server to make sure the data is not modified by the player)

		-- send the request to craft the item or tell user they don't have proper items
		net.Start( "getCraftables" )
		net.SendToServer( Entity( 1 ) )
	end

	-- Used to open the panel, you can replace the key or change it to a chat command, simply use the displayPanel() command to open it
	hook.Add( "KeyPress", "keypress_use_hi", function( ply, key )
		if ( key == IN_USE ) then
			displayPanel()
		end
	end )
end