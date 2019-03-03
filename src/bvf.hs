{-=BasicVariantFilter (BVF): A Haskell-based solution to Lymphoma=-}
{-=project variants_merged.tsv files basic filtering=-}
{-=pipeline.=-}
{-=Author: Matthew Mosior=-}
{-=Version: 1.0=-}
{-=Synopsis:  This Haskell Script will take in=-} 
{-=a merged_variants.tsv and output a .tsv file=-} 
{-=to either stdout, or to a user-specified output file=-}
{-=with all of the variants that pass basic filtering=-} 


{-Imports-}

import Control.Arrow as CA
import Control.Monad as CM
import Data.Char as DC
import Data.List as DL
import Data.List.Split as DLS
import Data.Maybe as DM
import Data.Tuple as DT
import System.Console.GetOpt as SCG
import System.Directory as SD
import System.Environment as SE
import System.Exit as SX
import System.IO as SIO
import System.IO.Temp as SIOT
import System.Process as SP
import Text.PrettyPrint.Boxes as TPB

{---------} 


{-Custom CML Option Datatype.-}

data Flag 
    = Verbose               -- -v
    | Version               -- -V -?
    | OutputFile String     -- -o
    | FilterFields String   -- -F
    | StripHeader           -- -S
    | Help                  -- --help
    deriving (Eq,Ord,Show) 

{-----------------------------}

{-Custom bool functions for Flag Datatype.-}

isOutputFile :: Flag -> Bool
isOutputFile (OutputFile _) = True
isOutputFile _              = False    

isFilterFields :: Flag -> Bool
isFilterFields (FilterFields _) = True
isFilterFields _                = False

isStripHeader :: Flag -> Bool
isStripHeader StripHeader = True
isStripHeader _           = False

{------------------------------------------}

{-Custom extraction functions for Flag Datatype.-}

extractOutputFile :: Flag -> String
extractOutputFile (OutputFile x) = x

extractFilterFields :: Flag -> String
extractFilterFields (FilterFields x) = x

{------------------------------------------------}


{-Option Description function relating to datatype above.-}

options :: [OptDescr Flag]
options =
    [ Option ['v']      ["verbose"]      (NoArg Verbose)                "Output on stderr.",
      Option ['V','?']  ["version"]      (NoArg Version)                "Show version number.",
      Option ['o']      ["outputfile"]   (ReqArg OutputFile "OUTFILE")  "The output file.",
      Option ['F']      ["filterfields"] (ReqArg FilterFields "FIELDS") "The fields to filter on.",
      Option ['S']      ["stripheader"]  (NoArg StripHeader)            "Strip the headers in the file.",
      Option []         ["help"]         (NoArg Help)                   "Print this help message."
    ] 

{---------------------------------------------------------}


{-Function to correctly parse the flags.-}

compilerOpts :: [String] -> IO ([Flag],String)
compilerOpts argv =
    case getOpt Permute options argv of
        (args,file,[]) ->
            if null file
                then do hPutStrLn stderr (nullerror ++ github ++ SCG.usageInfo header options)
                        SX.exitWith (SX.ExitFailure 1)  
                else if DL.elem Help args
                    then do hPutStrLn stderr (SCG.usageInfo header options)
                            SX.exitWith SX.ExitSuccess
                    else if DL.elem Version args
                        then do hPutStrLn stderr (version ++ SCG.usageInfo header options)
                                SX.exitWith SX.ExitSuccess
                        else if DL.length file > 1 
                            then do hPutStrLn stderr (flerror ++ github ++ SCG.usageInfo header options)
                                    SX.exitWith (SX.ExitFailure 1)
                            else if (DL.length (DL.filter (isFilterFields) args) > 0) && 
                                    (not (filterFieldsCheck (extractFilterFields (DL.head (DL.filter (isFilterFields) args))))) 
                                then do hPutStrLn stderr (fferror ++ github ++ SCG.usageInfo header options)
                                        SX.exitWith (SX.ExitFailure 1)
                                else return (DL.nub args, DL.concat file) 
        (_,_,errors) -> do
            hPutStrLn stderr (DL.concat errors ++ SCG.usageInfo header options)
            SX.exitWith (SX.ExitFailure 1)
        where 
            header    = "Usage: bvf [-vV?ioF] [file]"
            version   = "Basic Variant Filter (BVF), Version 1.0.\n"
            github    = "Please see https://github.com/Matthew-Mosior/Basic-Variant-Filter/wiki for more information.\n"
            nullerror = "Null error.  Please provide at least one input file.\n" 
            flerror   = "Incorrect number of input files:  Please provide one input file.\n"
            fferror   = "Incorrect structure of the filtration string (;:~;).\n" 

{----------------------------------------}


{-General Utility Functions.-}

--isSubsetOf -> This function will
--be used in the stripHeader function.
xs `isSubsetOf` ys = any (`elem` ys) xs

--lineFeed -> This function will
--read the file in and split on
--whitespace, returning a list
--of lists.
lineFeed :: String -> [[String]]
lineFeed [] = []
lineFeed xs = DL.map DL.words (DL.lines xs)

--mapNotLast -> This function will
--work like the traditional map 
--function in Data.List, but not
--map to the last element of a list.
mapNotLast :: (a -> a) -> [a] -> [a]
mapNotLast fn []     = []
mapNotLast fn [x]    = [x]
mapNotLast fn (x:xs) = fn x : mapNotLast fn xs

--mapTuple -> This function will
--map a function across all elements
--of a two-tuple.
mapTuple = CM.join (***)

--matchedReplication -> This function will
--take in two lists, and replicate items in 
--one list as long as the other list.
matchedReplication :: [[String]] -> [Int] -> [[Int]]
matchedReplication [] []         = []
matchedReplication _  []         = []
matchedReplication [] _          = []
matchedReplication (x:xs) (y:ys) = [DL.replicate (DL.length x) y] ++ (matchedReplication xs ys)

--nestedCycle -> This function will
--repeat a list of numbers the length
--of another list.
nestedCycle :: [[String]] -> [Int] -> [[Int]]
nestedCycle [] []     = []
nestedCycle _ []      = []
nestedCycle [] _      = []
nestedCycle (x:xs) ys = [DL.take (DL.length x) ys] ++ (nestedCycle xs ys)

--orderList -> This function will
--order a nested list.
orderList :: [[String]] -> [[Int]] -> [[Int]] -> [[(String,Int,Int)]]
orderList [] [] []             = []
orderList [] [] _              = []
orderList [] _  []             = []
orderList _  [] []             = []
orderList _  _  []             = []
orderList [] _  _              = [] 
orderList _  [] _              = []
orderList (x:xs) (y:ys) (z:zs) = [DL.zip3 x y z] ++ (orderList xs ys zs)

--tripletFst -> This function will
--act as a fst but for a triplet.
tripletFst :: (String,Int,Int) -> String
tripletFst (x,y,z) = x

--tuplifyTwo -> This function will
--turn a list of two elements into
--a two-tuple.
tuplifyTwo :: [a] -> (a,a)
tuplifyTwo [x,y] = (x,y)

--customSplit -> This function will
--split a input by the basis of each
--characters character class.
customSplit :: String -> [(String,String)]
customSplit [] = []
customSplit (x:xs) = if (DC.isDigit x) || (DC.isLower x) || (DC.isUpper x) || (x == '.') || (x == '-') 
                         then [("",[x])] ++ customSplit xs
                         else [([x],"")] ++ customSplit xs

--customAggregate -> This function will
--aggregate the result of customSplit.
customAggregate :: [(String,String)] -> (String,String)
customAggregate [] = ([],[])
customAggregate xs = (DL.concat (DL.map (fst) xs),DL.concat (DL.map (snd) xs))

--singleunnest -> This function will
--unnest a list.
singleunnest :: [a] -> a
singleunnest [a] = a

--smallSort -> This function will
--perform sorting on lists of triplets.
smallSort :: [[(String,Int,Int)]] -> [[(String,Int,Int)]]
smallSort [] = []
smallSort (x:xs) = [DL.sortBy (\(_,_,a) (_,_,b) -> compare a b) x] ++ (smallSort xs)

--strongEq -> This function will
--serve as a stronger version of ==.
strongEq :: (Eq a) => [a] -> [a] -> Bool
strongEq x y = DL.null (x \\ y) && DL.null (y \\ x)

{----------------------------}


{-FilterFields Functions.-}

--ffgenerator -> This function will
--generate the list of acceptable
--numbers of filterfield delimiters.
ffgenerator :: [Int] -> [Int]
ffgenerator xs = xs ++ ffgenerator (DL.map (\n -> n + 4) xs)

--filterFieldsCheck -> This function will
--check for the appropriate number of 
--delimiters present in FilterFields.
filterFieldsCheck :: String -> Bool
filterFieldsCheck xs = if (DL.elem flaglength ffdelimiterlengths) && ((DL.filter (flip DL.elem ";:~") xs) == ffdelimitercycler)
                           then True
                           else False
    where
        flaglength         = DL.length (DL.filter (flip DL.elem ";:~") xs)
        ffdelimiterlengths = DL.take (DL.length (DL.filter (flip DL.elem ";:~") xs))
                           $ ffgenerator [5]
        ffdelimitercycler = DL.concat (DL.take (DL.length (DL.filter (flip DL.elem ";:~") xs)) 
                            (cycle [";",":","~","~"]))

--indexAdder -> This function will 
--add indexes to the input list.
indexAdder :: [[String]] -> [[(String,Int,Int)]]
indexAdder [] = []
indexAdder xs = orderList xs (matchedReplication xs [0..(DL.length xs - 1)]) (nestedCycle xs [0..])

--specificFilters -> This function will
--applied the prepared specific filtration
--elucidated by filterFields.
specificFilters :: [[String]] -> [[(String,Int,Int)]] -> [[(String,Int,Int)]]
specificFilters [] [] = []
specificFilters [] _  = []
specificFilters _  [] = []
specificFilters (x:xs) ys = do
    --Grab the sublist of ys that matches x (on head).
    let matchedys = DL.concat (DL.concatMap (\a -> DL.filter (DL.any (\(b,_,_) -> a == b)) ys) x) 
    --Grab the entire portion of matchedys that isn't the column header.
    let onlydata = DL.filter (\(y,_,_) -> not (DL.isInfixOf (x DL.!! 0)  y)) matchedys
    --Grab the entire portion of matchedys that is the column header.
    let notdata = DL.filter (\(y,_,_) -> (DL.isInfixOf (x DL.!! 0)  y)) matchedys  
    --Grab !! 1 of x.
    let onex = x DL.!! 1
    --Grab !! 2 of x.
    let twox = x DL.!! 2 
    --Grab !! 3 of x.
    let threex = x DL.!! 3
    --Grab the comparision tuple from threex.
    let threexcomparison = customAggregate (customSplit threex)   
    --Walk through all possibilities of entire field of delimiters.
    if (DL.elem ',' onex) && (DL.elem '+' twox) && (DL.isInfixOf ">=" threex) && ((fst (tuplifyTwo (DLS.splitOn "," onex))) == "x")
        then [((notdata) ++ (DL.filter (\(y,_,_) -> (DT.uncurry (+) (mapTuple (read :: String -> Int) (tuplifyTwo (DLS.splitOneOf ";:," y)))) >= read (snd threexcomparison))
            onlydata))]
          ++ (specificFilters xs ys)
        else if (DL.elem ',' onex) && (DL.elem '+' twox) && (DL.isInfixOf ">=" threex) && ((fst (tuplifyTwo (DLS.splitOn "," onex))) == "y")
            then [((notdata) ++ (DL.filter (\(y,_,_) -> (DT.uncurry (+) (DT.swap (mapTuple (read :: String -> Int) (tuplifyTwo (DLS.splitOneOf ";:," y))))) >= read (snd threexcomparison))
            onlydata))]
              ++ (specificFilters xs ys)
            else if (DL.elem ',' onex) && (DL.elem '+' twox) && (DL.isInfixOf "<=" threex) && ((fst (tuplifyTwo (DLS.splitOn "," onex))) == "x")
                then [((notdata) ++ (DL.filter (\(y,_,_) -> (DT.uncurry (+) (mapTuple (read :: String -> Int) (tuplifyTwo (DLS.splitOneOf ";:," y)))) <= read (snd threexcomparison))
            onlydata))]
                  ++ (specificFilters xs ys)
                else if (DL.elem ',' onex) && (DL.elem '+' twox) && (DL.isInfixOf "<=" threex) && ((fst (tuplifyTwo (DLS.splitOn "," onex))) == "y")
                    then [((notdata) ++ (DL.filter (\(y,_,_) -> (DT.uncurry (+) (DT.swap (mapTuple (read :: String -> Int) (tuplifyTwo (DLS.splitOneOf ";:," y))))) <= read (snd threexcomparison))
            onlydata))]
                      ++ (specificFilters xs ys)
                    else if (DL.elem ',' onex) && (DL.elem '-' twox) && (DL.isInfixOf ">=" threex) && ((fst (tuplifyTwo (DLS.splitOn "," onex))) == "x")
                        then [((notdata) ++ (DL.filter (\(y,_,_) -> (DT.uncurry (-) (mapTuple (read :: String -> Int) (tuplifyTwo (DLS.splitOneOf ";:," y)))) >= read (snd threexcomparison))
            onlydata))]
                          ++ (specificFilters xs ys)
                        else if (DL.elem ',' onex) && (DL.elem '-' twox) && (DL.isInfixOf ">=" threex) && ((fst (tuplifyTwo (DLS.splitOn "," onex))) == "y")
                            then [((notdata) ++ (DL.filter (\(y,_,_) -> (DT.uncurry (-) (DT.swap (mapTuple (read :: String -> Int) (tuplifyTwo (DLS.splitOneOf ";:," y))))) >= read (snd threexcomparison)) onlydata))]
                              ++ (specificFilters xs ys)
                            else if (DL.elem ',' onex) && (DL.elem '-' twox) && (DL.isInfixOf "<=" threex) && ((fst (tuplifyTwo (DLS.splitOn "," onex))) == "x")
                                then [((notdata) ++ (DL.filter (\(y,_,_) -> (DT.uncurry (-) (mapTuple (read :: String -> Int) (tuplifyTwo (DLS.splitOneOf ";:," y)))) <= read (snd threexcomparison))
            onlydata))]
                                  ++ (specificFilters xs ys)
                                else if (DL.elem ',' onex) && (DL.elem '-' twox) && (DL.isInfixOf "<=" threex) && ((fst (tuplifyTwo (DLS.splitOn "," onex))) == "y")
                                    then [((notdata) ++ (DL.filter (\(y,_,_) -> (DT.uncurry (-) (DT.swap (mapTuple (read :: String -> Int) (tuplifyTwo (DLS.splitOneOf ";:," y))))) >= read (snd threexcomparison))
            onlydata))]
                                      ++ (specificFilters xs ys)
                                    else if (DL.notElem ',' onex) && (DL.elem '|' twox) && (DL.isInfixOf ">=" threex)
                                        then [((notdata) ++ ((DL.filter (\(y,_,_) -> ((read :: String -> Double) y) >= (read :: String -> Double) (snd threexcomparison))
                                             onlydata)))]
                                          ++ (specificFilters xs ys)
                                        else if (DL.notElem ',' onex) && (DL.elem '|' twox) && (DL.isInfixOf "<=" threex)
                                            then [((notdata) ++ ((DL.filter (\(y,_,_) -> ((read :: String -> Double) y) <= (read :: String -> Double) (snd threexcomparison))
                                             onlydata)))] 
                                              ++ (specificFilters xs ys)
                                              else if (DL.notElem ',' onex) && (DL.elem '|' twox) && (DL.isInfixOf "==" threex)
                                                  then [((notdata) ++ ((DL.filter (\(y,_,_) -> y == (snd threexcomparison)) onlydata)))] 
                                                    ++ (specificFilters xs ys)
                                                  else (specificFilters xs ys)
        
--addNonFilters -> This function will
--add back the non-filtered field.
addNonFilters :: [[String]] -> [[(String,Int,Int)]] -> [[(String,Int,Int)]] -> [[(String,Int,Int)]]
addNonFilters [] [] [] = []
addNonFilters xs ys zs = (DL.filter (\a -> DL.notElem (tripletFst (DL.head a)) (DL.map (DL.head) xs)) ys) ++ zs

--reorderList -> This function will
--reorder a list based on another list.
reorderList :: [[(String,Int,Int)]] -> [[(String,Int,Int)]] -> [[(String,Int,Int)]]
reorderList [] [] = []
reorderList [] _  = []
reorderList _  [] = []
reorderList xs ys = DL.concatMap (\a -> DL.filter (\(b:bs) -> (tripletFst b) == (tripletFst a))  ys) (DL.map (DL.head) xs)

--processFilteredList -> This function will
--walk through a filtered and unfiltered list
--and determine necessary processing.
processFilteredList :: [[(String,Int,Int)]] -> [[(String,Int,Int)]] -> [[String]]
processFilteredList [] [] = []
processFilteredList xs ys = DL.map (DL.map (tripletFst)) (DL.map (fst) (DL.filter (\(a,b) -> strongEq a b) (DL.zip (xs) (smallSort (DL.groupBy (\(_,a,_) (_,b,_) -> a == b) (DL.sortBy (\(_,a,_) (_,b,_) -> compare a b) (DL.concat ys)))))))

--filterFields -> This function will
--filter a field by the corresponding
--field.
filterFields :: [Flag] -> [[String]] -> [[String]]
filterfields [] [] = []
filterFields _  [] = []
filterFields opts xs = if (DL.length (DL.filter (isFilterFields) opts) > 0)
                           then do
                               --Grab just "FIELDS". 
                               let ffields = (singleunnest (DL.filter (isFilterFields) opts))
                               --Extract the string from FilterFields. 
                               let ffstring = extractFilterFields ffields
                               --Remove beginning and ending delimiters.
                               let begendremoved = DL.init (DL.tail ffstring)
                               --Push the separate filtrations into a list.
                               let filteringlist = DLS.splitOn ";" begendremoved
                               --Get the field separated from the filtration condition.
                               let fieldandcondition = DL.map (DLS.splitOneOf ":~") filteringlist 
                               --Add indexes to xs.
                               let indexedxs = indexAdder xs
                               --Call specificFilters on fieldandcondition. 
                               let specificfiltered = specificFilters fieldandcondition (DL.transpose indexedxs)
                               --Add back the nonfilteredlists.
                               let nonfiltersadded = addNonFilters fieldandcondition (DL.transpose indexedxs) specificfiltered
                               --Reorder nonfiltersadded.
                               let reorderedlist = reorderList (DL.transpose indexedxs) nonfiltersadded
                               --Process the transposed reorderedlist.
                               processFilteredList indexedxs (DL.transpose reorderedlist)
                       else xs

{-------------------------}


{-stripHeader function.-}

--stripHeader -> This function will
--strip the headers from the input file.
stripHeader :: [Flag] -> [[String]] -> [[String]]
stripHeader [] [] = []
stripHeader _  [] = []
stripHeader opts xs = if DL.length (DL.filter (isStripHeader) opts) > 0 
                          then DL.filter (not . ((DL.head xs) `isSubsetOf`)) xs
                          else xs

{-----------------------}


{-Printing functions.-}

--tempFileCreation -> This function will
--print the file to stdout using
--readProcess of the unix tool cat.
catFile :: [[String]] -> IO ()
catFile [] = return ()
catFile xs = do
    --Open a temporary file.
    (tempfile,temph) <- SIOT.openTempFile "." "temp.txt"
    --Intercalate a tab, and then a newline into xs.
    let intercalatedxs = DL.intercalate "\n" (DL.map (DL.intercalate "\t") xs)
    --Add intercalatedxs to temp.txt.
    hPutStrLn temph intercalatedxs
    --Close the temporary file's handle.
    hClose temph
    --Print out the contents of tempfile to the screen using cat unix tool.
    (_,_,_,ph) <- SP.createProcess (SP.proc "cat" [tempfile])
    ec <- SP.waitForProcess ph
    case ec of
        SX.ExitSuccess   -> do SP.createProcess (SP.proc "rm" [tempfile])
                               return ()
        SX.ExitFailure _ -> do error "Could not remove temporary file."
                               return ()

--printFile -> This function will
--print the file to either stdout
--or to a output file based on
--command-lines options provided.
printFile :: [Flag] -> [[String]] -> IO ()
printFile [] [] = return ()
printFile [] _  = return ()
printFile _  [] = return ()
printFile opts xs = do
    --Grab just "OUTFILE".
    let outfile = DL.head (DL.filter (isOutputFile) opts)
    --Extract the string from FilterFields.
    let outfilestring = extractOutputFile outfile
    --mapNotLast tabs and newlines in xs.
    --let tabsandnewlinesadded = DL.map (\y -> [y]) (mapNotLast (++ "\n") (DL.map (DL.concat) (DL.map (mapNotLast (++ "\t")) xs))) 
    let tabsandnewlinesadded = DL.map (mapNotLast (++ "\t")) xs
    --Write the output to the user-specified filename.
    SIO.writeFile (outfilestring) $
                  (TPB.render $
                  (TPB.hsep 0 TPB.left . DL.map (TPB.vcat TPB.left) . DL.map (DL.map (TPB.text)))
                  (DL.transpose tabsandnewlinesadded)) 

{---------------------}


{-BVF Specific Function.-}

--processArgsAndFiles -> This function will
--walk through each of the command-line
--arguments and files provided by the user.
processArgsAndFiles :: ([Flag],String) -> IO ()
processArgsAndFiles ([],[]) = return () 
processArgsAndFiles (options,inputfile) = do
    --Read in the file.
    readinputfile <- SIO.readFile inputfile
    --Apply lineFeed function to inputfile.
    let processedfile = lineFeed readinputfile 
    --Transpose the lines to group them correctly.
    let transposedfile = DL.transpose processedfile 
    --Filter the file based on the filter fields header. 
    let filteredfile = filterFields options processedfile 
    --Strip the header out if it is supplied in the options.
    let strippedfile = stripHeader options filteredfile  
    --Print the file to stdout (cat) or to a file.
    if DL.length (DL.filter (isOutputFile) options) > 0 
        then printFile options strippedfile
        else catFile strippedfile

--processArgsAndContents -> This function will
--walk through each of the command-line
--arguments and files provided by the user.
processArgsAndContents :: ([Flag],String) -> IO ()
processArgsAndContents ([],[]) = return ()
processArgsAndContents (options,content) = do
    --Apply lineFeed function to inputfile.
    let processedfile = lineFeed content
    --Transpose the lines to group them correctly.
    let transposedfile = DL.transpose processedfile
    --Filter the file based on the filter fields header.
    let filteredfile = filterFields options processedfile
    --Strip the header out if it is supplied in the options.
    let strippedfile = stripHeader options filteredfile
    --Print the file to stdout (cat) or to a file.
    if DL.length (DL.filter (isOutputFile) options) > 0
        then printFile options strippedfile
        else catFile strippedfile

{-------------------------}


{-Main function.-}

main :: IO ()
main = do
    --Get command line arguments.
    (args,files) <- SE.getArgs >>= compilerOpts
    --See if files is null
    if null files
        then do --Get stdin.
                contents <- SIO.getContents
                --Run args and contents through processArgsandContents.
                processArgsAndContents (args,contents)
        else do --Run args and files through processArgsandFiles.
                processArgsAndFiles (args,files)
    
{----------------}
