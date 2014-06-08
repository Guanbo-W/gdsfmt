# ===========================================================
#     _/_/_/   _/_/_/  _/_/_/_/    _/_/_/_/  _/_/_/   _/_/_/
#      _/    _/       _/             _/    _/    _/   _/   _/
#     _/    _/       _/_/_/_/       _/    _/    _/   _/_/_/
#    _/    _/       _/             _/    _/    _/   _/
# _/_/_/   _/_/_/  _/_/_/_/_/     _/     _/_/_/   _/_/
# ===========================================================
#
# gdsfmt-main.r: the R interface of CoreArray library
#
# Copyright (C) 2011 - 2014		Xiuwen Zheng [zhengx@u.washington.edu]
#
# This file is part of CoreArray.
#
# CoreArray is free software: you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License Version 3 as
# published by the Free Software Foundation.
#
# CoreArray is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with CoreArray.
# If not, see <http://www.gnu.org/licenses/>.



###############################################################################
# File Operations
###############################################################################

#############################################################
# Create a new CoreArray Genomic Data Structure (GDS) file
#
createfn.gds <- function(filename)
{
	stopifnot(is.character(filename) & is.vector(filename))
	stopifnot(length(filename) == 1)

	# 'normalizePath' does not work if the file does not exist
	tmpf <- file(filename, "wb")
	close(tmpf)

	filename <- normalizePath(filename, mustWork=FALSE)
	ans <- .Call("gdsCreateGDS", filename, PACKAGE="gdsfmt")
	names(ans) <- c("filename", "id", "root", "readonly")
	ans$filename <- filename
	class(ans$root) <- "gdsn.class"
	class(ans) <- "gds.class"
	ans
}


#############################################################
# Open an existing file
#
openfn.gds <- function(filename, readonly=TRUE)
{
	stopifnot(is.character(filename) & is.vector(filename))
	stopifnot(length(filename) == 1)

	filename <- normalizePath(filename, mustWork=FALSE)
	ans <- .Call("gdsOpenGDS", filename, readonly, PACKAGE="gdsfmt")
	names(ans) <- c("filename", "id", "root", "readonly")
	ans$filename <- filename
	class(ans$root) <- "gdsn.class"
	class(ans) <- "gds.class"
	ans
}


#############################################################
# Close an open CoreArray Genomic Data Structure (GDS) file
#
closefn.gds <- function(gds)
{
	stopifnot(inherits(gds, "gds.class"))
	.Call("gdsCloseGDS", gds$id, PACKAGE="gdsfmt")
	invisible()
}


#############################################################
# Write the data cached in memory to disk
#
sync.gds <- function(gds)
{
	stopifnot(inherits(gds, "gds.class"))
	.Call("gdsSyncGDS", gds$id, PACKAGE="gdsfmt")
	invisible()
}


#############################################################
# Clean up fragments of a GDS file
#
cleanup.gds <- function(filename, verbose=TRUE)
{
	stopifnot(is.character(filename) & is.vector(filename))
	stopifnot(length(filename) == 1)

	.Call("gdsTidyUp", filename, verbose, PACKAGE="gdsfmt")
	invisible()
}





###############################################################################
# File Structure Operations
###############################################################################

#############################################################
# Get the number of variables in a specified folder
#
cnt.gdsn <- function(node)
{
	stopifnot(inherits(node, "gdsn.class"))
	.Call("gdsNodeChildCnt", node, PACKAGE="gdsfmt")
}


#############################################################
# Get the variable name of a node
#
name.gdsn <- function(node, fullname=FALSE)
{
	stopifnot(inherits(node, "gdsn.class"))

	.Call("gdsNodeName", node, fullname, PACKAGE="gdsfmt")
}


#############################################################
# Rename a GDS node
#
rename.gdsn <- function(node, newname)
{
	stopifnot(inherits(node, "gdsn.class"))
	stopifnot(is.character(newname) & is.vector(newname))
	stopifnot(length(newname) == 1)

	.Call("gdsRenameNode", node, newname, PACKAGE="gdsfmt")
	invisible()
}


#############################################################
# Get a list of names for the child nodes
#
ls.gdsn <- function(node)
{
	if (inherits(node, "gds.class"))
		node <- node$root
	stopifnot(inherits(node, "gdsn.class"))

	.Call("gdsNodeEnumName", node, PACKAGE="gdsfmt")
}


#############################################################
# Get a specified node
#
index.gdsn <- function(node, path=NULL, index=NULL, silent=FALSE)
{
	# check
	if (inherits(node, "gds.class"))
		node <- node$root
	stopifnot(inherits(node, "gdsn.class"))
	stopifnot(is.logical(silent) & is.vector(silent))
	stopifnot(length(silent) == 1)

	ans <- .Call("gdsNodeIndex", node, path, index, silent, PACKAGE="gdsfmt")
	if (!is.null(ans))
		class(ans) <- "gdsn.class"
	ans
}


#############################################################
# Get the descritpion of a specified node
#
objdesp.gdsn <- function(node)
{
	stopifnot(inherits(node, "gdsn.class"))

	ans <- .Call("gdsNodeObjDesp", node, PACKAGE="gdsfmt")
	names(ans) <- c("name", "fullname", "storage", "type", "is.array",
		"dim", "compress", "cpratio", "size", "good", "message")
	attr(ans$type, "levels") <- c("Label", "Folder", "VFolder", "Raw",
		"Integer", "Factor", "Logical", "Real", "String", "Unknown")
	attr(ans$type, "class") <- "factor"
	ans
}


#############################################################
# Add a GDS node
#
add.gdsn <- function(node, name, val=NULL, storage=storage.mode(val),
	valdim=NULL, compress=c("", "ZIP", "ZIP.fast", "ZIP.default", "ZIP.max"),
	closezip=FALSE, check=TRUE, replace=FALSE)
{
	if (inherits(node, "gds.class"))
		node <- node$root
	stopifnot(inherits(node, "gdsn.class"))

	if (missing(name))
		name <- paste("Item", cnt.gdsn(node)+1, sep="")
	stopifnot(is.character(name) & is.vector(name))
	stopifnot(length(name) == 1)

	stopifnot(is.character(storage) & is.vector(storage))
	stopifnot(length(storage) == 1)

	stopifnot(is.character(compress) & is.vector(compress))
	stopifnot(length(compress) > 0)
	compress <- compress[1L]

	stopifnot(is.logical(closezip) & is.vector(closezip))
	stopifnot(length(closezip) == 1)

	stopifnot(is.logical(check) & is.vector(check))
	stopifnot(length(check) == 1)

	stopifnot(is.logical(replace) & is.vector(replace))
	stopifnot(length(replace) == 1)

	ans <- .Call("gdsAddNode", node, name, val, storage, valdim, compress,
		closezip, check, replace, PACKAGE="gdsfmt")
	class(ans) <- "gdsn.class"

	if (storage == "list")
	{
		nm <- class(val)
		if (!identical(nm, "data.frame") & !("list" %in% nm))
			nm <- c(nm, "list")
		put.attr.gdsn(ans, "R.class", nm)

		nm <- names(val)
		for (i in 1:length(nm))
		{
			add.gdsn(ans, nm[i], val[[i]], compress=compress,
				closezip=closezip, check=check)
		}
	} else if (storage == "logical")
	{
		put.attr.gdsn(ans, "R.logical")
	} else if (is.factor(val))
	{
		put.attr.gdsn(ans, "R.class", "factor")
		put.attr.gdsn(ans, "R.levels", levels(val))
	}

	ans
}


#############################################################
# Add a (virtual) folder
#
addfolder.gdsn <- function(node, name, type=c("directory", "virtual"),
	gds.fn="", replace=FALSE)
{
	if (inherits(node, "gds.class"))
		node <- node$root
	stopifnot(inherits(node, "gdsn.class"))

	if (missing(name))
		name <- paste("Item", cnt.gdsn(node)+1, sep="")
	stopifnot(is.character(name) & is.vector(name))
	stopifnot(length(name) == 1)

	type <- match.arg(type)
	if (type == "virtual")
	{
		stopifnot(is.character(gds.fn) & is.vector(gds.fn))
		stopifnot(length(gds.fn) == 1)
		stopifnot(!is.na(gds.fn))
		stopifnot(gds.fn != "")
	}

	stopifnot(is.logical(replace) & is.vector(replace))
	stopifnot(length(replace) == 1)

	# call C function
	ans <- .Call("gdsAddFolder", node, name, type, gds.fn, replace,
		PACKAGE="gdsfmt")
	class(ans) <- "gdsn.class"
	ans
}


#############################################################
# Add a GDS node with a file
#
addfile.gdsn <- function(node, name, filename,
	compress=c("ZIP", "ZIP.fast", "ZIP.default", "ZIP.max", ""),
	replace=FALSE)
{
	if (inherits(node, "gds.class"))
		node <- node$root
	stopifnot(inherits(node, "gdsn.class"))

	if (missing(name))
		name <- paste("Item", cnt.gdsn(node)+1, sep="")
	stopifnot(is.character(name) & is.vector(name))
	stopifnot(length(name) == 1)

	stopifnot(is.character(filename) & is.vector(filename))
	stopifnot(length(filename) == 1)

	stopifnot(is.character(compress) & is.vector(compress))
	stopifnot(length(compress) > 0)
	compress <- compress[1L]

	stopifnot(is.logical(replace) & is.vector(replace))
	stopifnot(length(replace) == 1)

	# call C function
	ans <- .Call("gdsAddFile", node, name, filename, compress,
		replace, PACKAGE="gdsfmt")
	class(ans) <- "gdsn.class"
	ans
}


#############################################################
# Get a file from a stream container
#
getfile.gdsn <- function(node, out.filename)
{
	stopifnot(inherits(node, "gdsn.class"))
	stopifnot(is.character(out.filename) & is.vector(out.filename))
	stopifnot(length(out.filename) == 1)

	.Call("gdsGetFile", node, out.filename, PACKAGE="gdsfmt")
	invisible()
}


#############################################################
# Delete a specified node
#
delete.gdsn <- function(node, force=FALSE)
{
	stopifnot(inherits(node, "gdsn.class"))
	stopifnot(is.logical(force) & is.vector(force))
	stopifnot(length(force) == 1)

	.Call("gdsDeleteNode", node, force, PACKAGE="gdsfmt")
	invisible()
}




###############################################################################
# Attribute
###############################################################################

#############################################################
# Add an attribute to a GDS node
#
put.attr.gdsn <- function(node, name, val=NULL)
{
	stopifnot(inherits(node, "gdsn.class"))
	stopifnot(is.character(name) & is.vector(name))
	stopifnot(length(name) == 1)

	.Call("gdsPutAttr", node, name, val, PACKAGE="gdsfmt")
	invisible()
}


#############################################################
# Get the attributes of a GDS node
#
get.attr.gdsn <- function(node)
{
	stopifnot(inherits(node, "gdsn.class"))
	.Call("gdsGetAttr", node, PACKAGE="gdsfmt")
}


#############################################################
# Remove an attribute from a GDS node
#
delete.attr.gdsn <- function(node, name)
{
	stopifnot(inherits(node, "gdsn.class"))
	stopifnot(is.character(name) & is.vector(name))
	stopifnot(length(name) == 1)

	.Call("gdsDeleteAttr", node, name, PACKAGE="gdsfmt")
	invisible()
}





###############################################################################
# Data Operations
###############################################################################

#############################################################
# Modify the data compression mode of data field
#
compression.gdsn <- function(node,
	compress=c("", "ZIP", "ZIP.fast", "ZIP.default", "ZIP.max") )
{
	stopifnot(inherits(node, "gdsn.class"))
	stopifnot(is.character(compress) & is.vector(compress))
	stopifnot(length(compress) > 0)
	compress <- compress[1L]

	.Call("gdsObjCompress", node, compress, PACKAGE="gdsfmt")
	return(node)
}


#############################################################
# Get into read mode of compression
#
readmode.gdsn <- function(node)
{
	stopifnot(inherits(node, "gdsn.class"))
	.Call("gdsObjCompressClose", node, PACKAGE="gdsfmt")
	return(node)
}


#############################################################
# Set the new dimension of the data field for a GDS node
#
setdim.gdsn <- function(node, valdim)
{
	stopifnot(inherits(node, "gdsn.class"))
	stopifnot(is.numeric(valdim) & is.vector(valdim))

	.Call("gdsObjSetDim", node, valdim, PACKAGE="gdsfmt")
	return(node)
}


#############################################################
# Append data to a specified variable
#
append.gdsn <- function(node, val, check=TRUE)
{
	stopifnot(inherits(node, "gdsn.class"))

	.Call("gdsObjAppend", node, val, check, PACKAGE="gdsfmt")
	invisible()
}


#############################################################
# Read data field of a GDS node
#
read.gdsn <- function(node, start=NULL, count=NULL, simplify=TRUE)
{
	stopifnot(inherits(node, "gdsn.class"))

	if (is.null(start) & is.null(count))
	{
		rvattr <- get.attr.gdsn(node)
		rvclass <- rvattr$R.class
		if (!is.null(rvclass))
		{
			if (identical(rvclass, "data.frame") | ("list" %in% rvclass))
			{
				cnt <- cnt.gdsn(node)
				r <- vector("list", cnt)
				if (cnt > 0)
				{
					for (i in 1:cnt)
					{
						n <- index.gdsn(node, index=i)
						r[[i]] <- read.gdsn(n)
						names(r)[i] <- name.gdsn(n)
					}
				}

				if (identical(rvclass, "data.frame"))
				{
					r <- as.data.frame(r, stringsAsFactors=FALSE)
				} else {
					rvclass <- setdiff(rvclass, "list")
					if (length(rvclass) > 0)
						class(r) <- rvclass
				}

				return(r)
			}
		}
	}

	.Call("gdsObjReadData", node, start, count, simplify, PACKAGE="gdsfmt")
}


#############################################################
# Read data field of a GDS node
#
readex.gdsn <- function(node, sel=NULL, simplify=TRUE)
{
	stopifnot(inherits(node, "gdsn.class"))
	stopifnot(is.null(sel) | is.logical(sel) | is.list(sel))

	if (!is.null(sel))
	{
		if (is.logical(sel)) sel <- list(d1=sel)
		# read
		.Call("gdsObjReadExData", node, sel, simplify, PACKAGE="gdsfmt")
	} else {
		# output
		read.gdsn(node)
	}
}


#############################################################
# Apply functions over array margins of a GDS node
#
apply.gdsn <- function(node, margin, FUN, selection=NULL,
	as.is = c("list", "integer", "double", "character", "none"), ...)
{
	# check
	if (inherits(node, "gdsn.class"))
	{
		stopifnot(inherits(node, "gdsn.class"))
		stopifnot(is.numeric(margin) & (length(margin)==1))
		stopifnot(is.null(selection) | is.list(selection))

		node <- list(node)
		if (!is.null(selection))
			selection <- list(selection)
	} else {
		if (!is.list(node))
			stop("'node' should be 'gdsn.class' or a list of 'gdsn.class' objects.")
		for (i in 1:length(node))
		{
			if (!inherits(node[[i]], "gdsn.class"))
				stop(sprintf("node[[%d]] should be an object of 'gdsn' class.", i))
		}
	
		stopifnot(is.numeric(margin))
		stopifnot(length(margin) == length(node))
	
		stopifnot(is.null(selection) | is.list(selection))
		if (!is.null(selection))
			stopifnot(length(selection) == length(node))
	}

	as.is <- match.arg(as.is)
	FUN <- match.fun(FUN)

	ans <- .Call("gds_apply_call", node, as.integer(margin), FUN,
		selection, as.is, new.env())
	if (is.null(ans)) ans <- invisible()
	ans
}


#############################################################
# Apply functions over array margins of a list of GDS nodes in parallel
#
clusterApply.gdsn <- function(cl, gds.fn, node.name, margin,
	FUN, selection=NULL,
	as.is = c("list", "integer", "double", "character", "none"), ...)
{
	#########################################################
	# library
	#
	if (!require(parallel))
		stop("the `parallel' package should be installed.")


	#########################################################
	# check
	#
	stopifnot(inherits(cl, "cluster"))
	stopifnot(is.character(gds.fn) & (length(gds.fn)==1))
	stopifnot(is.character(node.name))
	stopifnot(is.numeric(margin) & (length(margin)==length(node.name)))
	margin <- as.integer(margin)

	if (!is.null(selection))
	{
		if (!is.list(selection[[1]]))
			selection <- list(selection)
	}


	as.is <- match.arg(as.is)
	FUN <- match.fun(FUN)


	#########################################################
	# new selection
	#

	ifopen <- TRUE
	gfile <- openfn.gds(gds.fn)
	on.exit({ if (ifopen) closefn.gds(gfile) })

	nd_nodes <- vector("list", length(node.name))
	names(nd_nodes) <- names(node.name)
	for (i in 1:length(nd_nodes))
	{
		v <- index.gdsn(gfile, path=node.name[i], silent=TRUE)
		nd_nodes[[i]] <- v
		if (is.null(v))
		{
			stop(sprintf("There is no node \"%s\" in the specified gds file.",
				node.name[i]))
		}
	}

	new.selection <- .Call("gds_apply_create_selection", nd_nodes,
		margin, selection)

	# the count of elements
	MarginCount <- sum(new.selection[[1]][[ margin[1] ]], na.rm=TRUE)
	if (MarginCount <= 0)
		return(invisible())


	#########################################################
	# run
	#

	if (length(cl) > 1)
	{
		# close the GDS file
		ifopen <- FALSE
		closefn.gds(gfile)

		clseq <- splitIndices(MarginCount, length(cl))
		sel.list <- vector("list", length(cl))
		
		# for - loop: multi core
		for (i in 1:length(cl))
		{
			tmp <- new.selection
	
			# for - loop: multiple variables
			for (j in 1:length(tmp))
			{
				sel <- tmp[[j]]
				idx <- which(sel[[ margin[j] ]])
				flag <- rep(FALSE, length(sel[[ margin[j] ]]))
				flag[ idx[ clseq[[i]] ] ] <- TRUE
				sel[[ margin[j] ]] <- flag
				tmp[[j]] <- sel
			}
	
			sel.list[[i]] <- tmp
		}

		# enumerate
		ans <- clusterApply(cl, sel.list, fun =
				function(sel, gds.fn, node.name, margin, FUN, as.is, ...)
			{
				# load the package
				library(gdsfmt)

				# open the file
				gfile <- openfn.gds(gds.fn)
				on.exit({ closefn.gds(gfile) })

				nd_nodes <- vector("list", length(node.name))
				names(nd_nodes) <- names(node.name)
				for (i in 1:length(nd_nodes))
					nd_nodes[[i]] <- index.gdsn(gfile, path=node.name[i])

				# apply
				apply.gdsn(nd_nodes, margin, FUN, sel, as.is, ...)

			}, gds.fn=gds.fn, node.name=node.name, margin=margin,
				FUN=FUN, as.is=as.is, ...
		)

		if (as.is != "none")
		{
			ans <- unlist(ans, recursive=FALSE)
		}

		ans
	} else{
		apply.gdsn(nd_nodes, margin, FUN, selection, as.is, ...)
	}
}


#############################################################
# Write data to a GDS node
#
write.gdsn <- function(node, val, start=NULL, count=NULL, check=TRUE)
{
	stopifnot(inherits(node, "gdsn.class"))
	stopifnot(!missing(val))

	if (is.null(start) & is.null(count))
	{
		.Call("gdsObjWriteAll", node, val, check, PACKAGE="gdsfmt")
	} else {
		.Call("gdsObjWriteData", node, val, start, count, check,
			PACKAGE="gdsfmt")
	}
	
	invisible()
}


#############################################################
# Assign a GDS variable from another variable
#
assign.gdsn <- function(dest.obj, src.obj, append)
{
	stopifnot(inherits(dest.obj, "gdsn.class"))
	stopifnot(inherits(src.obj, "gdsn.class"))
	stopifnot(is.logical(append) & is.vector(append))
	stopifnot(length(append) == 1)

	# call C function
	.Call("gdsAssign", dest.obj, src.obj, append, PACKAGE="gdsfmt")

	invisible()
}


#############################################################
# Caching the data associated with a GDS variable
#
cache.gdsn <- function(node)
{
	stopifnot(inherits(node, "gdsn.class"))

	# call C function
	.Call("gdsCache", node, PACKAGE="gdsfmt")

	invisible()
}




###############################################################################
# Error function
###############################################################################

#############################################################
# Return the last error
#
lasterr.gds <- function()
{
	.Call("gdsLastErrGDS", PACKAGE="gdsfmt")
}





##################################################################################
# R Generic functions
##################################################################################

print.gds.class <- function(x, all=FALSE, ...)
{
	# check
	stopifnot(inherits(x, "gds.class"))
	stopifnot(is.logical(all) & is.vector(all))
	stopifnot(length(all) == 1)

	.Call("gdsFileValid", x$id, PACKAGE="gdsfmt")
	cat("File: ", x$filename, "\n", sep="");
	print(x$root)
}

print.gdsn.class <- function(x, expand=TRUE, all=FALSE, ...)
{
	enum <- function(node, space, level, expand, fullname)
	{
		at <- get.attr.gdsn(node)
		if (!all)
		{
			if ("R.invisible" %in% names(at))
				return(invisible())
		}

		n <- objdesp.gdsn(node)
		if (n$type == "Label")
		{
			lText <- " "; rText <- " "
		} else if (n$type == "VFolder")
		{
			lText <- if (n$good) "[ -->" else "[ -X-"
			rText <- "]"
		} else if (n$type == "Folder")
		{
			lText <- "["; rText <- "]"
		} else if (n$type == "Unknown")
		{
			lText <- "  -X-"; rText <- ""
		} else {
			lText <- "{"; rText <- "}"
		}
		cat(space, "+ ", name.gdsn(node, fullname), "	",
			lText, " ", n$storage, sep="")

		# if logical, factor, list, or data.frame
		if (n$type == "Logical")
		{
			cat(",logical")
		} else if (n$type == "Factor")
		{
			cat(",factor")
		} else if ("R.class" %in% names(at))
		{
			if (n$storage != "")
				cat(",")
			if (!is.null(at$R.class))
				cat(paste(at$R.class, sep="", collapse=","))
		}

		# show the dimension
		if (!is.null(n$dim))
		{
			cat(" ")
			cat(n$dim, sep="x")
		}

		# show compression
		if (is.character(n$compress))
		{
			if (n$compress != "") cat("", n$compress)
		}
		if (is.numeric(n$cpratio))
		{
			if (is.finite(n$cpratio))
				cat(sprintf("(%0.2f%%)", 100*n$cpratio))
		}

		if (length(at) > 0)
			cat(" ", rText, " *\n", sep="")
		else
			cat(" ", rText, "\n", sep="")

		if (expand)
		{
			cnt <- cnt.gdsn(node)
			if (cnt > 0)
			{
				for (i in 1:cnt)
				{
					m <- index.gdsn(node, index=i)
					if (level==1)
						s <- paste("|--", space, sep="")
					else
						s <- paste("|  ", space, sep="")
					enum(m, s, level+1, TRUE, FALSE)
				}
			}
		}
	}

	# check
	stopifnot(inherits(x, "gdsn.class"))
	stopifnot(is.logical(all) & is.vector(all))
	stopifnot(length(all) == 1)
	stopifnot(is.logical(expand) & is.vector(expand))
	stopifnot(length(expand) == 1)

	.Call("gdsNodeValid", x, PACKAGE="gdsfmt")
	enum(x, "", 1, expand, TRUE)
	invisible()
}





##################################################################################
# Unit testing
##################################################################################

#############################################################
# Run all unit tests
#
gdsUnitTest <- function()
{
	# load R packages
	if (!require(RUnit))
		stop("Please install RUnit package!")

	# define a test suite
	myTestSuite <- defineTestSuite("gdsfmt examples",
		system.file("unitTests", package = "gdsfmt"))

	# run the test suite
	testResult <- runTestSuite(myTestSuite)

	# print detailed text protocol to standard out:
	printTextProtocol(testResult)

	# return
	invisible()
}
