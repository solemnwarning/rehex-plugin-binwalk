-- Binwalk analysis plugin for REHex
-- Copyright (C) 2024 Daniel Collins <solemnwarning@solemnwarning.net>
--
-- This program is free software; you can redistribute it and/or modify it
-- under the terms of the GNU General Public License version 2 as published by
-- the Free Software Foundation.
--
-- This program is distributed in the hope that it will be useful, but WITHOUT
-- ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
-- more details.
--
-- You should have received a copy of the GNU General Public License along with
-- this program; if not, write to the Free Software Foundation, Inc., 51
-- Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

-- Name or path of the Python interpreter.
local PYTHON_INTERP = "python3"

-- This is a stub program we pipe into the Python interpreter to do binwalk
-- analysis and then read the output it pipes back to us.
local BINWALK_STUB = [[
import binwalk
import os

results = binwalk.scan(os.environ["BINWALK_ANALYSIS_FILE"], signature=True, quiet=True)

for module in results:
    for result in module.results:
        print("%u\t%u\t%s" % (result.offset, result.size, result.description))
]]

-- Error codes which may be returned by wx.wxProcess.Kill()
local WXK_ERRORS = {
	[wx.wxKILL_BAD_SIGNAL]    = "wxKILL_BAD_SIGNAL",
	[wx.wxKILL_ACCESS_DENIED] = "wxKILL_ACCESS_DENIED",
	[wx.wxKILL_NO_PROCESS]    = "wxKILL_NO_PROCESS",
	[wx.wxKILL_ERROR]         = "wxKILL_ERROR",
}

rehex.AddToToolsMenu("Binwalk signature analysis", function(mainwindow)
	local doc = mainwindow:active_document()
	local filename = doc:get_filename()
	
	if filename == ""
	then
		wx.wxMessageBox("File must be saved before analysing with Binwalk", "Error", wx.wxOK | wx.wxICON_INFORMATION)
		return
	end
	
	local progress_dialog = wx.wxProgressDialog(
		"Analysing file",
		"Running binwalk...",
		100,
		mainwindow,
		wx.wxPD_CAN_ABORT | wx.wxPD_ELAPSED_TIME | wx.wxPD_APP_MODAL)
	progress_dialog:Show()
	
	doc:transact_begin("Binwalk signature analysis")
	
	local ok, err = pcall(function()
		local cancelled = false
		
		local timer = wx.wxTimer.new()
		
		-- We store the name of the current file in the environment for the stub process.
		wx.wxSetEnv("BINWALK_ANALYSIS_FILE", filename)
		
		local proc = wx.wxProcess.new()
		proc:Redirect()
		
		local stdout_buf = ""
		local stderr_buf = ""
		
		proc:Connect(wx.wxID_ANY, wx.wxEVT_END_PROCESS, function(event)
			-- The binwalk child process has finished.
			
			if cancelled
			then
				-- User already pressed the cancel button.
				return
			end
			
			-- Buffer any output from the child process
			
			local stdout = proc:GetInputStream()
			local stderr = proc:GetErrorStream()
			
			while not stdout:Eof()
			do
				stdout_buf = stdout_buf .. stdout:Read(1024)
			end
	
			while not stderr:Eof()
			do
				stderr_buf = stderr_buf .. stderr:Read(1024)
			end
			
			if event:GetExitCode() == 0
			then
				-- Child exited gracefully, add comments for anything it found and
				-- commit the transaction.
				
				for offset, length, desc in string.gmatch(stdout_buf, "(%d+)\t(%d+)\t(.-)\n") do
					doc:set_comment(
						rehex.BitOffset(tonumber(offset), 0),
						rehex.BitOffset(tonumber(length), 0),
						rehex.Comment.new(desc))
				end
				
				doc:transact_commit()
			else
				-- Child died, rollback the transaction and display anything
				-- written to its stderr.
				
				doc:transact_rollback()
				wx.wxMessageBox(stderr_buf, "Error executing binwalk")
			end
			
			timer:Stop()
			timer = nil
			
			progress_dialog:Destroy()
		end)
		
		wx.wxExecute(PYTHON_INTERP, wx.wxEXEC_ASYNC, proc)
		
		local stdin = proc:GetOutputStream()
		stdin:Write(BINWALK_STUB, BINWALK_STUB:len())
		stdin:Close()
		
		timer:Connect(wx.wxID_ANY, wx.wxEVT_TIMER, function(event)
			progress_dialog:Pulse()
			
			if progress_dialog:WasCancelled() and not cancelled
			then
				-- User has pushed the cancel button, we rollback the transaction
				-- and kill the child, ignoring any further data from it.
				
				cancelled = true
				
				local ke = wx.wxProcess.Kill(proc:GetPid())
				if ke ~= wx.wxKILL_OK
				then
					if WXK_ERRORS[ke] ~= nil
					then
						rehex.print_error("Unexpected error when killing binwalk process: " .. WXK_ERRORS[ke])
					else
						rehex.print_error("Unexpected error when killing binwalk process: " .. ke)
					end
				end
				
				doc:transact_rollback()
				
				timer:Stop()
				timer = nil
				
				progress_dialog:Destroy()
			end
		end)
		
		timer:Start(100, wxTIMER_CONTINUOUS)
	end)
	
	wx.wxUnsetEnv("BINWALK_ANALYSIS_FILE")
	
	if not ok
	then
		-- An error occured while starting the analysis, rollback the transaction and
		-- display the exception message.
		
		doc:transact_rollback()
		wx.wxMessageBox(err, "Error")
		
		progress_dialog:Destroy()
	end
end)
