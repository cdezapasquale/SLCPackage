###########################################################################################
#######functions and params
###########################################################################################

##############################################################################
########Import related
##############################################################################

import_FileWithinZip_fread = function(zipfilename, FileWithinZipFilename){

  unzip(zipfilename,files = FileWithinZipFilename)
  outputdf = fread(FileWithinZipFilename, stringsAsFactors=FALSE)
  file.remove(FileWithinZipFilename)

  return (outputdf)

}

import_clean_xlsx <- function (excelfilename, worksheet, range){
  df <- read_excel(excelfilename,
                   sheet = worksheet,
                   col_names = TRUE,
                   col_types = NULL,
                   guess_max = 10000,
                   range = range)
  df <- df[rowSums(is.na(df)) != ncol(df),]
  df <- df %>% dplyr::rename_all(list(~make.names(.)))

  return(df)
}







##############################################################################
########Export related
##############################################################################

df_to_excel_old= function(dataframename_list, filename){
  datafr=c()
  for (i in dataframename_list){

    datafr[[i]]=get(i)
  }
  write_xlsx(datafr, paste0(filename,".xlsx"))
}
#
# df_to_excel = function(dataframes, filename, freezepane_rowlist=NULL, freezepane_collist=NULL){
#
#   wb <- createWorkbook()
#   for (i in 1:length( dataframes)    ){
#     addWorksheet(wb, dataframes[[i]])
#     writeData(wb, sheet = dataframes[[i]] , x = get(dataframes[[i]]), withFilter = TRUE)
#
#     if (!is.null(freezepane_rowlist) & length(freezepane_rowlist)>=i  ) {
#       if (freezepane_rowlist[i]>0) {
#
#         freezePane(wb, dataframes[[i]], firstActiveRow = freezepane_rowlist[[i]] )
#       }}
#
#     if (!is.null(freezepane_collist) & length(freezepane_collist)>=i   ) {
#       if (freezepane_collist[i]>0) {
#         freezePane(wb, dataframes[[i]], firstActiveCol = freezepane_collist[[i]] )
#       }}
#   }
#   saveWorkbook(wb, paste0(filename,".xlsx") , overwrite = TRUE)

  # Instructions
  ##dataframes= list('df','df2')
  ## Zero if no freeze panes required
  # freezepane_rowlist=c(2, 2)
  # freezepane_collist =c(2, 2)
  #
  # setwd(directory_current)
  # data_to_excel(dataframes, filename, row_list)
#}


df_to_excel = function(dataframes, filename, freezepane_rowlist, freezepane_collist){

  wb <- createWorkbook()

  for (i in 1:length( dataframes)    ){
    addWorksheet(wb, dataframes[[i]])
    writeData(wb, sheet = dataframes[[i]] , x = get(dataframes[[i]]), withFilter = TRUE)

    if (freezepane_rowlist[[i]]>1 & freezepane_collist[[i]] >1) {
      freezePane(wb, dataframes[[i]], firstActiveRow = freezepane_rowlist[[i]], firstActiveCol= freezepane_collist[[i]] )
    }

    else if (freezepane_rowlist[[i]]>1 & freezepane_collist[[i]] < 2)
    {
      freezePane(wb, dataframes[[i]], firstActiveRow = freezepane_rowlist[[i]] )
    }

    else if (freezepane_rowlist[[i]]<2 & freezepane_collist[[i]] >1)
    {
      freezePane(wb, dataframes[[i]], firstActiveCol = freezepane_collist[[i]] )
    }
    saveWorkbook(wb, paste0(filename,".xlsx") , overwrite = TRUE)
  }

  # Instructions
  ##dataframes= list('df','df2')
  ## Zero if no freeze panes required
  # freezepane_rowlist=c(2, 2)
  # freezepane_collist =c(2, 2)
  #
  # setwd(directory_current)
  # data_to_excel(dataframes, filename, freezepane_rowlist, freezepane_collist)
}





export_df_to_csv_zip <- function (inputdf, outputfilename_no_extension)
{
  #write.csv(inputdf, paste0(outputfilename_no_extension,".csv"), row.names=FALSE)
  fwrite(inputdf, paste0(outputfilename_no_extension,".csv"), row.names=FALSE)


  zip(zipfile = paste0(outputfilename_no_extension,".zip"), files = paste0(outputfilename_no_extension,".csv"))
  file.remove(paste0(outputfilename_no_extension,".csv"))
  #cat(paste0("Export ", inputdf, "to ", outputfilename_no_extension, ".zip complete"))
  cat(paste0("Export ", deparse(substitute(inputdf)), " to ", outputfilename_no_extension, ".zip complete"))
}

##############################################################################
########Formatting/Data manipulation
##############################################################################


sprintf_formatter_percent <- function (input_df, inputcolumn, format)
{
  #temp <- input_df
  input_df[[inputcolumn]] = sprintf(paste0(format), 100*input_df[[inputcolumn]])
  #temp[[inputcolumn]] = sprintf(paste0(format), 100*temp[[inputcolumn]])
  #input_df <<- temp
  #input_df <<- input_df
  return(input_df)
}

sprintf_formatter_numeric <- function (input_df, inputcolumn, format)
{
  input_df[[inputcolumn]] = sprintf(paste0(format), input_df[[inputcolumn]])
  return(input_df)
}


spread_2var <- function(df, key, value) {
  # quote key
  keyq <- rlang::enquo(key)
  # break value vector into quotes
  valueq <- rlang::enquo(value)
  s <- rlang::quos(!!valueq)
  df %>% gather(variable, value, !!!s) %>%
    unite(temp, !!keyq, variable) %>%
    spread(temp, value)
}

spread_multivar <- function(df, key, value) {
  # quote key
  keyq <- rlang::enquo(key)
  # break value vector into quotes
  valueq <- rlang::enquo(value)
  s <- rlang::quos(!!valueq)

  # df <- df %>%
  #   group_by(!!sym(key)) %>%
  #   mutate (grouped_id = row_number()) %>%
  #   ungroup()
  #necessary to fix this bug but I couldn't get it to work properly. Using the above code would crash if this function is called from another function
  #https://www.r-bloggers.com/workaround-for-tidyrspread-with-duplicate-row-identifiers/

  df %>% gather(variable, value, !!!s) %>%
    unite(temp, !!keyq, variable) %>%
    spread(temp, value) #%>%
    #select (-grouped_id)
}

find_string_position <- function (inputdf, column, pattern_to_search, instance_num)
{
  outputdf <- as.data.frame(t(as.data.frame(str_locate_all(pattern = pattern_to_search, as.matrix(inputdf[[column]])))))
  outputdf <- setDT(outputdf, keep.rownames = TRUE)[] %>%
    filter(grepl("start",rn)) %>%
    select (colnames(outputdf)[instance_num+1])
  return (as.matrix(outputdf))
}


column_stats = function(inputdf, columnn, return_option){

  #Column type
  cat ("\n Input column type: ", typeof(inputdf[[columnn]]), "\n\n")

  #Stats on missing
  inputdf[[columnn]] = ifelse (is.na(inputdf[[columnn]]) | inputdf[[columnn]] == "", "Missing", inputdf[[columnn]])
  temp_missing_rows <- inputdf %>%
    filter (inputdf[[columnn]] == "Missing")
  cat ("# of rows missing: ", nrow(temp_missing_rows), "\n",
       "% of rows missing: ", nrow(temp_missing_rows)/nrow(inputdf), "\n")



  if (is.numeric(inputdf[[columnn]])) {

    #Stats on negative
    temp_negative <- inputdf %>%
      filter (inputdf[[columnn]] < 0)

    cat ("# of rows <0: ", nrow(temp_negative), "\n",
         "% of rows <0: ", nrow(temp_negative)/nrow(inputdf), "\n")


    #Value distribution

    cat ("\n Min: ", min (inputdf[[columnn]]),
         "\n Mean: ", mean (inputdf[[columnn]]),
         "\n Max: ",max (inputdf[[columnn]]),"\n")

    for (i in 1:20) {
      percentile = i*5/100
      cat (percentile, " Percentile: ", quantile(inputdf[[columnn]], percentile, names = FALSE), "\n")
    }
  }

  #Summarise stats
  cat ("\n Count by column value \n")

  temp <- inputdf %>%
   group_by(!!!syms(columnn)) %>%
   summarise (count = n()) %>%
   ungroup()
  print(temp)

  if (return_option == TRUE ) {
    return(temp)
  }

}






replaceNA_with = function(inputdf, col, NAreplacement){

  cat ("Column stats before replacement \n")
  column_stats (inputdf, col, return_option = FALSE)

  inputdf[[col]] = ifelse (is.na(inputdf[[col]]) | inputdf[[col]] == "", NAreplacement, inputdf[[col]])

  cat ("Column stats after replacement \n")
  column_stats (inputdf, col, return_option = FALSE)

  return(inputdf)
}


##############################################################################
########Import stage/Data related
##############################################################################

merge_diagnostics <- function (input_df, output_df, df_params)
{

  cat("# duplicates created after merging: ", nrow(output_df) - nrow(input_df), "\n")
  cat("# columns created after merging: ", ncol(output_df) - ncol(input_df), "\n")
  cat("# columns in the parameter df: ", ncol(df_params), "\n")
  cat("#Increase in rows due to merging: ", nrow(output_df)-nrow(input_df))

}


#Using NAIC6D, map in NAIC6D related fields

# import_params_NAIC6DMap <- function () #to delete in favour of import_params_NAIC6DMap_all
# {
#   setwd(directory_current)
#   params_NAIC6DMap <- read_xlsx(filename_paramsglobal,sheet = "NAICMap", range = "A1:X1067") %>%
#     select (NAIC6D, NAIC5D, NAIC4D, NAIC3D, NAIC2D,
#             NAIC6DDesc, NAIC5DDesc, NAIC4DDesc, NAIC3DDesc,	NAIC2DDesc, NAIC2DDescShort,
#             IndGrouped, IndGroupedShort, PreferredAtNAIC6D,
#             RevVer_LiabAll, RevVer_FireAll,RevVer_All, ReviewFlag_N6D, ReviewFlag_N6D_Tenant)
#
#   return (params_NAIC6DMap)
# }

import_params_NAIC6DMap_all <- function ()
{
  currwd = getwd()

  setwd(directory_current)
  params_NAIC6DMap <- read_xlsx(filename_paramsglobal,sheet = "NAICMap", range = "A1:X1067")
  setwd(currwd)
  return (params_NAIC6DMap)
}


import_params_postcode <- function ()
{
  currwd = getwd()

  setwd(directory_current)
  temp <- read_xlsx(filename_paramsglobal,sheet = "PostcodeMap", range = "A1:E4000")
  setwd(currwd)
  return (temp)
}

import_params_CCodeMap <- function ()
{
  params <- read_xlsx("0.0 Params.Global.xlsx",sheet = "CCodeMap", range = "A1:U10000", guess_max = 10000) %>%
    select (IndustryCode_Internal, IndustryDesc_Internal, NAIC6D, PreferredAtBrokerCode, ReviewNotes_ChubbCode)
  params <- params[rowSums(is.na(params)) != ncol(params),]
  params <- params %>% dplyr::rename_all(list(~make.names(.)))

  return (params)
}

merge_NAICFields_allcol <- function (input_df, input_df_mergeclass, param_mergeclass)
{

  params_NAIC6DMap <- import_params_NAIC6DMap_all()

  # params_NAIC6DMap <- read_xlsx(filename_paramsglobal,sheet = "NAICMap", range = "A1:W1067") %>%
  #   select (NAIC6D, NAIC5D, NAIC4D, NAIC3D, NAIC2D,
  #           NAIC6DDesc, NAIC5DDesc, NAIC4DDesc, NAIC3DDesc,	NAIC2DDesc, NAIC2DDescShort,
  #           IndGrouped, IndGroupedShort, PreferredAtNAIC6D,
  #           RevVer_LiabAll, RevVer_FireAll,RevVer_All, ReviewFlag_N6D)

  output_df <- merge(x = input_df, y = params_NAIC6DMap, by.x = input_df_mergeclass, by.y=param_mergeclass, all.x = TRUE) %>%
    select (-ReviewFlag_N6D_Tenant) #because this is used to merge against main occupation code, not tenant occ
  merge_diagnostics (input_df, output_df, params_NAIC6DMap)

  return (output_df)
}

merge_NAICFields_choosecol <- function (input_df, input_df_mergeclass, param_mergeclass, col_to_merge)
{

  params_NAIC6DMap <- import_params_NAIC6DMap_all()

  output_df <- merge(x = input_df, y = params_NAIC6DMap %>% select (param_mergeclass, col_to_merge), by.x = input_df_mergeclass, by.y=param_mergeclass, all.x = TRUE)
  merge_diagnostics (input_df, output_df, params_NAIC6DMap)

  return (output_df)
}

merge_NAICFields_ChooseColThenRename <- function (input_df, input_df_mergeclass, param_mergeclass, col_to_merge, col_to_merge_newname)
{

  params_NAIC6DMap <- import_params_NAIC6DMap_all()

  output_df <- merge(x = input_df, y = params_NAIC6DMap %>% select (param_mergeclass, col_to_merge) %>%
                      rename ({{col_to_merge_newname}} := {{col_to_merge}}),
                    by.x = input_df_mergeclass,
                     by.y=param_mergeclass,
                     all.x = TRUE)
  merge_diagnostics (input_df, output_df, params_NAIC6DMap)

  return (output_df)
}

merge_CCodeFields_1col <- function (input_df, input_df_mergeclass, param_mergeclass, col_to_merge) #rename this to choose column
{

  params <- import_params_CCodeMap()

  output_df <- merge(x = input_df, y = params %>% select (param_mergeclass, col_to_merge) %>% unique(), by.x = input_df_mergeclass, by.y=param_mergeclass, all.x = TRUE)
  merge_diagnostics (input_df, output_df, params)

  return (output_df)
}


#Re-order NAIC fields so they appear first
reorder_NAICFields <- function (input_df)
{

  col_list <- c(colnames(input_df))

  col_list_first <- c ("NAIC6D", "NAIC5D", "NAIC4D", "NAIC3D", "NAIC2D",
                       "NAIC6DDesc", "NAIC5DDesc", "NAIC4DDesc", "NAIC3DDesc",	"NAIC2DDesc", "NAIC2DDescShort",
                       "IndGrouped", "IndGroupedShort", "PreferredAtNAIC6D",
                       "RevVer_LiabAll", "RevVer_FireAll","RevVer_All", "ReviewNotes_N6D")

  col_list_last <- setdiff(col_list,col_list_first)
  col_list_final <- c(col_list_first,col_list_last)

  output_df <- input_df %>%
    select (c(col_list_final))

  return (output_df)
}

#import production table no NAIC
import_PT <- function (inputfilename, sheetname, inputrange, inputrows, inputversion)
{

  df <- read_excel(inputfilename,
                   sheet = sheetname,
                   col_names = TRUE,
                   col_types = NULL,
                   na = "",
                   #skip = 2,
                   range = inputrange,
                   guess_max = inputrows,
                   trim_ws = TRUE)
  df <- df[rowSums(is.na(df)) != ncol(df),]
  df <- df %>% dplyr::rename_all(list(~make.names(.)))
  df$Start.Version = df$Start.Version %>% replace_na(0)
  df$End.Version = df$End.Version %>% replace_na(0)

  df2 <- df %>%
    filter ((Start.Version <= inputversion & End.Version >= (inputversion)) |
              (Start.Version <= inputversion & End.Version == 0)
    ) #%>%
    #select (-Data.Headings)

  return (df2)
}

#import production table NAIC ver
import_PT_NAIC <- function (inputfilename, sheetname, inputrange, inputrows, inputversion)
{
  df <- import_PT (inputfilename, sheetname, inputrange, inputrows, inputversion)

  df2 <- df %>%
    rename (NAIC6D = NAIC)

  df2 <- merge_NAICFields_allcol (input_df = df2, "NAIC6D","NAIC6D")
  df2 <- reorder_NAICFields (df2)

  return (df2)
}


import_PT_user <- function (inputfilename, sheetname, inputrange, inputrows)
{

  df <- read_excel(inputfilename,
                   sheet = sheetname,
                   col_names = TRUE,
                   col_types = NULL,
                   na = "",
                   #skip = 2,
                   range = inputrange,
                   guess_max = inputrows,
                   trim_ws = TRUE)
  df <- df[rowSums(is.na(df)) != ncol(df),]
  df <- df %>% dplyr::rename_all(list(~make.names(.)))

  df <- unique(df)


    #drop_na(df[,1])

  return (df)
}




##############################################################################
########Create new fields
##############################################################################



createcommonfields <- function(input_df, sectionprem_curr)
{

  input_df[["CompetitiveIndex_Proposed"]] = input_df[["RecalcBizPackPremium"]]/input_df[["AvgCompetitorQuote"]]
  input_df[["CompetitiveIndex_Current"]] = input_df[["CurrentBizPackPremium"]]/input_df[["AvgCompetitorQuote"]]
  input_df[["PremInc"]] = input_df[["Recalc_sub_premium"]] - input_df[[sectionprem_curr]]
  input_df[["PremIncPerc"]] = input_df[["Recalc_sub_premium"]]/input_df[[sectionprem_curr]] - 1
  input_df[["CI_new_mixweighted"]] = input_df[["CompetitiveIndex_Proposed"]] * input_df[["SectionPremProportionCurr"]]
  input_df[["CI_cur_mixweighted"]] = input_df[["CompetitiveIndex_Current"]] * input_df[["SectionPremProportionCurr"]]
  input_df[["QuoteNumberTrunc"]] = str_sub(input_df[["QuoteNumber"]], -4)
  input_df[["CI_theoretical"]] = input_df[["CompetitiveIndex_Current"]] * (1+input_df[["PremIncPerc"]])
  input_df[["boundflag"]] <- ifelse(input_df[["QuoteOutcome"]] == "Bound", "Bound", "NotBound")
  #input_df[["NAIC6d_trunc"]] = str_sub(paste0(input_df[["NAIC6d"]]), -4)
  input_df[["NAIC6DTrunc"]] = str_sub(input_df[["NAIC6D"]], -4)

  return(input_df)
}

create_UsedForRatingFlag <- function (input_df){
  input_df <- input_df %>%
    mutate(
      UsedForRatingFlag = ifelse (ZeroPremFlag ==	"NonZero" &
                                  Location_Count_Flag	== "Single-Location" &
                                  EntsiaPremReconcile	== "Yes" &
                                  AvgCompetitorQuote > 0,
                                    "Yes","No"))
  return (input_df[["UsedForRatingFlag"]])
}



##############################################################################
########Calculate mean of truncated column
##############################################################################

#for a vector, remove bottom and top percentiles and returns the mean
mean_truncate <- function(data_vector, bottom_percentile, top_percentile)
{
  p_top <- quantile(data_vector, top_percentile)
  p_bottom <- quantile(data_vector, bottom_percentile)

  meanTrunc <- mean(data_vector[which(data_vector < p_top &
                                        data_vector > p_bottom)])
  return(meanTrunc)
}

##############################################################################
########Import rates by NAIC
##############################################################################

import_rates_byNAIC <- function(filename, sheetname, range_NAICList, range_rates)
{

  NAICList <- read_excel(filename,
                         sheet = sheetname,
                         col_names = TRUE,
                         col_types = NULL,
                         na = "",
                         guess_max = 10000,
                         range = range_NAICList
  )

  rates <- read_excel(filename,
                      sheet = sheetname,
                      col_names = TRUE,
                      col_types = NULL,
                      na = "",
                      guess_max = 10000,
                      range = range_rates)
  df <- cbind(NAICList,rates)

  df <- df[rowSums(is.na(df)) != ncol(df),]
  df <- df %>% dplyr::rename_all(list(~make.names(.)))


  return(df)
}


#importing SICurve params
create_SIcurveratetable <- function (SICurveMin, SICurveHeight, SICurveDecay)
{
  output <- merge(x = SICurveDecay, y = SICurveHeight %>% filter(NAIC_6D_Used != ""), by = "NAIC_6D_Used", all.x = TRUE)
  output <- merge(x = output, y = SICurveMin %>% filter(NAIC_6D_Used != ""), by = "NAIC_6D_Used", all.x = TRUE)

  for (i in c(2,3,4,5,6,7,8))
  {
    output[ , i] = sprintf("%.0f%%", 100*output[ , i])
    output[ , i+7] = sprintf("%.1f", output[ , i+7])
    output[ , i+14] = sprintf("$%.2fm", output[ , i+14]/1000000)
    output[ , i+14] <- paste0(output[ , i+14],", ", output[ , i+7],", ", output[ , i])
  }
  output <- output %>%
    select(NAIC_6D_Used, 16:22)
  return(output)
}


##############################################################################
########ChubbCodeLoopingList
##############################################################################

# ChubbCodeLoopingList <- function(input_df)
# {
#
#   quotecount_byNAIC <- input_df %>%
#     select(IndustryCode_NAIC6d,Occupation_target_flag) %>%
#     group_by(IndustryCode_NAIC6d) %>%
#     summarise(NAIC6D_count = n()) %>%
#     arrange(-NAIC6D_count)
#
#   quotecount_IndustryDesc_Grouped <- input_df %>%
#     select(IndustryDesc_Grouped,Occupation_target_flag) %>%
#     #filter (Occupation_target_flag == "Preferred") %>%
#     group_by(IndustryDesc_Grouped) %>%
#     summarise(IndustryDesc_Grouped_count = n()) %>%
#     arrange(-IndustryDesc_Grouped_count)
#
#   output_df <- merge(x = input_df, y = quotecount_byNAIC,
#                      by = "IndustryCode_NAIC6d", all.x = TRUE) %>%
#     select(IndustryDesc_Grouped, IndustryCode_NAIC6d, IndustryDesc_Internal, IndustryCode_Internal, Occupation_target_flag, NAIC6D_count)
#
#   output_df <- merge(x = output_df, y = quotecount_IndustryDesc_Grouped,
#                      by = "IndustryDesc_Grouped", all.x = TRUE) %>%
#     select(IndustryDesc_Grouped, IndustryCode_NAIC6d, IndustryDesc_Internal, IndustryCode_Internal, Occupation_target_flag, NAIC6D_count, IndustryDesc_Grouped_count)
#
#   output_df <- output_df %>%
#     #select(IndustryCode_NAIC6d, IndustryDesc_Internal, Occupation_target_flag) %>%
#     filter (Occupation_target_flag == "Preferred") %>%
#     group_by(IndustryDesc_Grouped,IndustryCode_NAIC6d, IndustryDesc_Internal, IndustryCode_Internal, IndustryDesc_Grouped_count, NAIC6D_count) %>%
#     summarise(IndustryDesc_Internal_count = n()) %>%
#     arrange (-IndustryDesc_Grouped_count,-NAIC6D_count, -IndustryDesc_Internal_count)
#
#
#   return(output_df)
# }



create_export_list <- function(input_df, reviewfieldname)
{
  #Creates a unique list of NAIC2Ds with associated fields

  #choose fields for output_df
  output_df <- input_df %>%
    select(IndustryDesc_Grouped, NAIC2DDesc, NAIC2D,
           NAIC4DDesc,NAIC4D,
           NAIC6D,
           IndustryDesc_Internal, IndustryCode_Internal,
           PreferredAtNAIC6D, !! sym(reviewfieldname))

  #create count by N6D
  quotecount_byNAIC <- input_df %>%
    #select(NAIC6D,PreferredAtNAIC6D) %>%
    select(NAIC6D) %>%
    group_by(NAIC6D) %>%
    summarise(NAIC6D_count = n()) %>%
    arrange(-NAIC6D_count) %>%
    ungroup()

  output_df <- merge(x = input_df, y = quotecount_byNAIC,
                     by = "NAIC6D", all.x = TRUE) #%>%

  #create count by N2D
  quotecount_NAIC2DDesc <- input_df %>%
    select(NAIC2DDesc) %>%
    group_by(NAIC2DDesc) %>%
    summarise(NAIC2DDesc_count = n()) %>%
    arrange(-NAIC2DDesc_count) %>%
    ungroup()
  output_df <- merge(x = output_df, y = quotecount_NAIC2DDesc,
                     by = "NAIC2DDesc", all.x = TRUE) #%>%

  #create count by N4D
  quotecount_NAIC4DDesc <- input_df %>%
    #select(NAIC4DDesc,PreferredAtNAIC6D) %>%
    select(NAIC4DDesc) %>%
    group_by(NAIC4DDesc) %>%
    summarise(NAIC4DDesc_count = n()) %>%
    arrange(-NAIC4DDesc_count) %>%
    ungroup()
  output_df <- merge(x = output_df, y = quotecount_NAIC4DDesc,
                     by = "NAIC4DDesc", all.x = TRUE) #%>%

  #create count by industry grouped
  quotecount_IndGrouped <- input_df %>%
    select(IndustryDesc_Grouped) %>%
    group_by(IndustryDesc_Grouped) %>%
    summarise(IndGrouped_count = n()) %>%
    arrange(-IndGrouped_count) %>%
    ungroup()
  output_df <- merge(x = output_df, y = quotecount_IndGrouped,
                     by = "IndustryDesc_Grouped", all.x = TRUE) #%>%
  #

  #summarise and reate count by Chubb codes
  output_df <- output_df %>%
    group_by(IndustryDesc_Grouped, NAIC2DDesc, NAIC2D,
             NAIC4DDesc, NAIC4D,
             NAIC6D,
             IndustryDesc_Internal, IndustryCode_Internal,
             PreferredAtNAIC6D,
             IndGrouped_count,
             NAIC2DDesc_count,
             NAIC4DDesc_count,
             NAIC6D_count, !! sym(reviewfieldname)) %>%
    #NAIC6D_count) %>%
    summarise(IndustryDesc_Internal_count = n()) %>%
    arrange (-IndGrouped_count, IndustryDesc_Grouped, -NAIC2DDesc_count, NAIC2DDesc, -NAIC4DDesc_count, -NAIC6D_count, -IndustryDesc_Internal_count) %>%
    ungroup()

  #df_reviewcol <- input_df %>%
  #  select (NAIC6D, reviewfieldname)

  #output_df  <- merge(x = output_df, y = df_reviewcol, by = "NAIC6D", all.x = TRUE)


  return(output_df)
}

  create_export_list2 <- function(input_df)
  {
    #Creates a unique list of occupation codes wtih associated count

    #choose fields for output_df
    output_df <- input_df %>%
      select(IndGroupedShort, NAIC2DDesc, NAIC2D,
             NAIC4DDesc,NAIC4D,
             NAIC6D,
             IndustryDesc_Internal, IndustryCode_Internal,
             PreferredAtNAIC6D, PreferredAtBrokerCode)

    #create count by N6D
    quotecount_byNAIC <- input_df %>%
      #select(NAIC6D,PreferredAtNAIC6D) %>%
      select(NAIC6D) %>%
      group_by(NAIC6D) %>%
      summarise(NAIC6D_count = n()) %>%
      arrange(-NAIC6D_count) %>%
      ungroup()
    output_df <- merge(x = input_df, y = quotecount_byNAIC,
                       by = "NAIC6D", all.x = TRUE) #%>%

    #create count by N2D
    quotecount_NAIC2DDesc <- input_df %>%
      select(NAIC2DDesc) %>%
      group_by(NAIC2DDesc) %>%
      summarise(NAIC2DDesc_count = n()) %>%
      arrange(-NAIC2DDesc_count) %>%
      ungroup()
    output_df <- merge(x = output_df, y = quotecount_NAIC2DDesc,
                       by = "NAIC2DDesc", all.x = TRUE) #%>%

    #create count by N4D
    quotecount_NAIC4DDesc <- input_df %>%
      #select(NAIC4DDesc,PreferredAtNAIC6D) %>%
      select(NAIC4DDesc) %>%
      group_by(NAIC4DDesc) %>%
      summarise(NAIC4DDesc_count = n()) %>%
      arrange(-NAIC4DDesc_count) %>%
      ungroup()
    output_df <- merge(x = output_df, y = quotecount_NAIC4DDesc,
                       by = "NAIC4DDesc", all.x = TRUE) #%>%

    #create count by industry grouped
    quotecount_IndGrouped <- input_df %>%
      select(IndGroupedShort) %>%
      group_by(IndGroupedShort) %>%
      summarise(IndGrouped_count = n()) %>%
      arrange(-IndGrouped_count) %>%
      ungroup()
    output_df <- merge(x = output_df, y = quotecount_IndGrouped,
                       by = "IndGroupedShort", all.x = TRUE) #%>%
    #

    #summarise and re-create count by Chubb codes
    output_df <- output_df %>%
      group_by(IndGroupedShort, NAIC2DDesc, NAIC2D,
               NAIC4DDesc, NAIC4D,
               NAIC6D,
               IndustryDesc_Internal, IndustryCode_Internal,
               PreferredAtNAIC6D,
               PreferredAtBrokerCode,
               IndGrouped_count,
               NAIC2DDesc_count,
               NAIC4DDesc_count,
               NAIC6D_count) %>%
      #NAIC6D_count) %>%
      summarise(IndustryDesc_Internal_count = n()) %>%
      arrange (-IndGrouped_count, IndGroupedShort, -NAIC2DDesc_count, NAIC2DDesc, -NAIC4DDesc_count, -NAIC6D_count, -IndustryDesc_Internal_count) %>%
      ungroup()

    return(output_df)
  }


create_export_list3 <- function(input_df, target_col)
{
  count_col_name = paste0(target_col,"_count")

  output_df <- input_df %>%
     group_by(!!sym(target_col)) %>%
     summarise (count=n()) %>%
     ungroup() %>%
     arrange (-count)

  colnames(output_df)[2] <- count_col_name

  return(output_df)
}


##input_df = ModelData_train
##groupby_col = "NAIC6DToRate"

##temp3 <- temp %>% filter (NAIC6DToRate == 722513) %>%
  ##select (NAIC6DToRate, NAIC6DToRate_count)


SummariseCount_and_merge <- function(input_df, groupby_col, count_col_name)
{
  #count_col_name = paste0(groupby_col,"_count")

  temp_merge <- input_df %>%
    group_by(!!sym(groupby_col)) %>%
    summarise (count=n()) %>%
    ungroup()# %>%
    #arrange (-count)

  colnames(temp_merge)[2] <- count_col_name

  temp <- merge(x = input_df, y = temp_merge, by = groupby_col, all.x = TRUE)

  return(temp)
}

  #create occupation codes, description and opportunity count for merging
  create_oppcount_byOcc <- function (inputdf, class, countname)
  {
    temp <- inputdf %>%
      group_by(!!sym(class)) %>%
      summarise (n()) %>%
      ungroup() %>%
      arrange (-.[[2]])

    colnames(temp)[2] <- paste0(countname)

    return(temp)
  }

  #merges in industry group opportunity and bound count
 # df_with_count = Looper_selected
  merge_indgrp_counts <- function (input_df, df_with_count)
  {

    temp_byIndGrp <- input_df
    temp_occ_opp_count_byIndGrp <- create_oppcount_byOcc (df_with_count %>% filter (Opp_YrMth == latest_mth), class = "IndGroupedShort", countname = "IndGrouped_opp_count")
    temp_byIndGrp <- merge(x = temp_byIndGrp, y = temp_occ_opp_count_byIndGrp, by = "IndGroupedShort", all.x = TRUE)

    temp_occ_bnd_count_byIndGrp <- create_oppcount_byOcc (df_with_count %>% filter (Opp_YrMth == latest_mth, QuoteOutcomeGrp=="Bound"), class = "IndGroupedShort", countname = "IndGrouped_bnd_count")
    temp_byIndGrp <- merge(x = temp_byIndGrp, y = temp_occ_bnd_count_byIndGrp, by = "IndGroupedShort", all.x = TRUE) %>%
      arrange (-IndGrouped_opp_count) %>%
      select(IndGroupedShort, IndGrouped_opp_count, IndGrouped_bnd_count, everything())

    temp_byIndGrp$IndGrouped_opp_count =  temp_byIndGrp$IndGrouped_opp_count %>% replace_na(0)
    temp_byIndGrp$IndGrouped_bnd_count =  temp_byIndGrp$IndGrouped_bnd_count  %>% replace_na(0)

    return (temp_byIndGrp)
  }

  #merges in industry group opportunity and bound count
  merge_CCode_counts_desc <- function (input_df, df_with_count)
  {

    temp_summ_byCCode <- input_df

    temp_occ_bnd_count_byCCode <- create_oppcount_byOcc (df_with_count %>% filter (Opp_YrMth == latest_mth, QuoteOutcomeGrp=="Bound"), class = "IndustryCode_Internal", countname = "CCode_bnd_count")
    temp_occ_bnd_count_byCCode$IndustryCode_Internal <- as.character(temp_occ_bnd_count_byCCode$IndustryCode_Internal) #to align we convert to character as Chubb code should be character
    temp_summ_byCCode2 <- merge(x = temp_summ_byCCode, y = temp_occ_bnd_count_byCCode, by = "IndustryCode_Internal", all.x = TRUE)

    temp_occ_opp_count_byCCode <- create_oppcount_byOcc (df_with_count %>% filter (Opp_YrMth == latest_mth), class = "IndustryCode_Internal", countname = "CCode_opp_count")
    temp_occ_opp_count_byCCode$IndustryCode_Internal <- as.character(temp_occ_opp_count_byCCode$IndustryCode_Internal) #to align we convert to character as Chubb code should be character
    temp_summ_byCCode3 <- merge(x = temp_summ_byCCode2, y = temp_occ_opp_count_byCCode, by = "IndustryCode_Internal", all.x = TRUE)


    temp_occ_desc_map <- df_with_count %>%
      select (IndustryCode_Internal, IndustryDesc_Internal, IndGroupedShort) %>%
      unique()
    temp_occ_desc_map$IndustryCode_Internal <- as.character(temp_occ_desc_map$IndustryCode_Internal) #to align we convert to character as Chubb code should be character
    temp_occ_desc_map$IndustryCode_Internal = trimws(temp_occ_desc_map$IndustryCode_Internal)

    temp_summ_byCCode4 <- merge(x = temp_summ_byCCode3, y = temp_occ_desc_map, by = "IndustryCode_Internal", all.x = TRUE) %>%
      select(IndustryCode_Internal, IndustryDesc_Internal, IndGroupedShort, CCode_opp_count, CCode_bnd_count, everything()) %>%
      arrange(-CCode_opp_count)
    temp_summ_byCCode4$CCode_bnd_count =  temp_summ_byCCode4$CCode_bnd_count %>% replace_na(0)

    return(temp_summ_byCCode4)
  }



##############################################################################
########Competitive Index Main Chart
##############################################################################


create_compindex_chart <- function(input_df, chart_title, chart_caption, limit)
{

  axis_major_unit = ceiling(limit/10/100)*100

  if(nrow(input_df)<= 20) {
    label_percentile = 1
  } else label_percentile = 20/nrow(input_df)

  label_threshold_upper = quantile(input_df[["CompetitiveIndex_Current"]], 1- label_percentile, names = FALSE)
  label_threshold_lower = quantile(input_df[["CompetitiveIndex_Current"]], label_percentile, names = FALSE)
  input_df[["label_col_filter"]] = ifelse(input_df[["CompetitiveIndex_Current"]] >= label_threshold_upper | input_df[["CompetitiveIndex_Current"]] <= label_threshold_lower,
                                          input_df[["QuoteNumberTrunc"]], c(""))

  input_df <- input_df[order(input_df[["boundflag"]]),]

  chart <-input_df %>%
    ggplot() +
    labs(title=chart_title,
         y="Chubb Premium",
         x="Ave. Competitor Premium",
         caption=chart_caption)+
    scale_x_continuous(breaks = seq(0, limit, by = axis_major_unit), limits = c(0, limit)) +
    scale_y_continuous(breaks = seq(0, limit, by= axis_major_unit), limits = c(0, limit)) +
    geom_abline(col="#293D4B")+
    theme_minimal()+
    geom_point(aes(x=AvgCompetitorQuote,
                   y=CurrentBizPackPremium,
                   colour = "Current",
                   shape = boundflag), size=2) +
    scale_shape_manual(values=c(1, 2), name = "Outcome") +
    geom_point(aes(x=AvgCompetitorQuote,
                   y=RecalcBizPackPremium,
                   colour = "Proposed"), size=2) +
    scale_colour_manual("",
                        breaks = c("Current", "Proposed"),
                        values = c("#A38A00", "#1561AD"))+
    geom_text_repel(aes(x = AvgCompetitorQuote, y = CurrentBizPackPremium, label=label_col_filter),
                    size = 2, color = "#293D4B")
  rm(label_threshold_upper, label_threshold_lower, label_percentile)
  return (chart)
}


create_CIchart_CurrVsProp <- function(input_df,
                                      chart_title,
                                      chart_caption,
                                      limit,
                                      x_axis1,
                                      y_axis1,
                                      shape_axis1,
                                      x_axis2,
                                      y_axis2#,
                                      #shape_axis2 #not used
                                      )
{

  axis_major_unit = ceiling(limit/10/100)*100

  #for labelling - not used
  # if(nrow(input_df)<= 20) {
  #   label_percentile = 1
  # } else label_percentile = 20/nrow(input_df)
  #
  # label_threshold_upper = quantile(input_df[["CompetitiveIndex_Current"]], 1- label_percentile, names = FALSE)
  # label_threshold_lower = quantile(input_df[["CompetitiveIndex_Current"]], label_percentile, names = FALSE)
  # input_df[["label_col_filter"]] = ifelse(input_df[["CompetitiveIndex_Current"]] >= label_threshold_upper | input_df[["CompetitiveIndex_Current"]] <= label_threshold_lower,
  #                                         input_df[["QuoteNumberTrunc"]], c(""))

  #sort by bound flag to standardise shape allocated to bound
  input_df <- input_df[order(input_df[[shape_axis1]]),]

  chart <-input_df %>%
    ggplot() +
    labs(title=chart_title,
         y="Chubb Premium",
         x="Ave. Competitor Premium",
         caption=chart_caption)+
    scale_x_continuous(breaks = seq(0, limit, by = axis_major_unit), limits = c(0, limit)) +
    scale_y_continuous(breaks = seq(0, limit, by= axis_major_unit), limits = c(0, limit)) +
    geom_abline(col="#293D4B")+
    theme_minimal()+
    geom_point(aes(x=input_df[[x_axis1]],
                   y=input_df[[y_axis1]],
                   colour = "Current",
                   shape = input_df[[shape_axis1]]), size=2) +
    scale_shape_manual(values=c(1, 2), name = "Outcome") +
    geom_point(aes(x=input_df[[x_axis2]],
                   y=input_df[[y_axis2]],
                   colour = "Proposed"), size=2) +
    scale_colour_manual("",
                        breaks = c("Current", "Proposed"),
                        values = c("#A38A00", "#1561AD"))#+
    #geom_text_repel(aes(x = AvgCompetitorQuote, y = CurrentBizPackPremium, label=label_col_filter),
    #                size = 2, color = "#293D4B")
  #rm(label_threshold_upper, label_threshold_lower, label_percentile)
  return (chart)
}


create_CIChart_monitoring <- function(input_df,
                                      chart_title,
                                      chart_caption,
                                      axis_limit,
                                      x_axis,
                                      y_axis,
                                      shape_axis)
{

  axis_major_unit = ceiling(axis_limit/10/100)*100

  #input_df <- input_df[order(-input_df[[shape_axis]]),]
  input_df <- input_df %>%
    arrange(input_df[[shape_axis]])

  #input_df[[x_axis]]= sprintf("%.0f", input_df[[x_axis]])
  #input_df[[y_axis]]= sprintf("%.0f", input_df[[y_axis]])

  chart <-input_df %>%
    ggplot() +
    labs(title=chart_title,
         y="Chubb Premium",
         x="Ave. Competitor Premium",
         caption=chart_caption)+
    scale_x_continuous(breaks = seq(0, axis_limit, by = axis_major_unit),
    #scale_x_log10(breaks = seq(0, axis_limit, by = axis_major_unit),
                       #limits = c(0, axis_limit),trans = log10_trans()) +
                       limits = c(0, axis_limit), labels = scales::comma) +
    scale_y_continuous(breaks = seq(0, axis_limit, by= axis_major_unit),
                       #limits = c(0, axis_limit),trans = "log10") +
                       limits = c(0, axis_limit),labels = scales::comma) +
    geom_abline(col="#293D4B")+
    theme_minimal()+
    geom_point(aes(x=input_df[[x_axis]],
                   y=input_df[[y_axis]],
                   # colour = "Current",
                   colour = input_df[[shape_axis]]
                   #shape = boundflag
    ),
    size=2
    ) +
    #scale_shape_manual(values=c(1, 2), name = "Outcome") +
    scale_colour_manual("",
                        breaks = c("NotBound", "Bound"),
                        values = c("#1561AD", "#A38A00"))# +
    #scale_x_log10(labels = scales::comma, limits = c(0.1,axis_limit)) +
    #scale_y_log10(labels = scales::comma, limits = c(0.1,axis_limit))
  # geom_text_repel(aes(x = AvgCompetitorQuote, y = CurrentBizPackPremium, label=label_col_filter),
  #                 size = 2, color = "#293D4B")
  #rm(label_threshold_upper, label_threshold_lower, label_percentile)
  return (chart)
}



CIChartTitle_PO_Fire <- function(inputdf)
{
  chart_title =paste0(
    "Tenant Info (T) | T.IndGrp:", unique(inputdf$Tenant_IndGroupedShort), " | ",
    "[", unique(inputdf$Tenant_PreferredAtNAIC6D),"] ",
    "T.N6D: ", unique(inputdf$Tenant_NAIC6D), " ", str_trunc(unique(inputdf$Tenant_NAIC6DDesc),35))

  return (chart_title)

}


CIChartTitle_Fire <- function(inputdf)
{
  chart_title =paste0(
    "IndGrp:", unique(inputdf$IndGroupedShort_ToRate), " | ",
    "[", unique(inputdf$PreferredAtNAIC6D_ToRate),"] ",
    "N6D: ", unique(inputdf$NAIC6DToRate), " ", str_trunc(unique(inputdf$NAIC6DDesc_ToRate),35), "\n",
    "LastVerReviewedFire@N6D: ", unique(inputdf$RevVer_FireAll_ToRate))
  return (chart_title)
}

CIChartTitle_N6D <- function(indgrp, N6D, N6DDesc, preferred)
{
  chart_title =paste0(
    "IndGrp: ", indgrp, " | ",
    "N6D: ", N6D, " ",
    "[", preferred,"] ",
    str_trunc(N6DDesc,35), "\n")
    #"LastVerRev. Liab: ", unique(subset$RevVer_LiabAll), " | ", "Fire: ", unique(subset$RevVer_FireAll), " | 5% most expensive quotes not plotted")
    #" | 5% most expensive quotes not plotted")
  return (chart_title)
}

CIChartTitle_CCode <- function(inputdf)
{
      chart_title =paste0(
        "IndGrp:", unique(inputdf$IndGroupedShort), " | ",
        "N6D: ",unique(inputdf$NAIC6D), " ", str_trunc(unique(inputdf$NAIC6DDesc), 30), "\n",
        "ChubbCode: ", unique(inputdf$IndustryCode_Internal), " ", str_trunc(unique(inputdf$IndustryDesc_Internal),30),
        " [", unique(inputdf$PreferredAtBrokerCode),"] ", "\n",
        "LastVerRev. Liab: ", unique(inputdf$RevVer_LiabAll), " | ", "Fire: ", unique(inputdf$RevVer_FireAll))

  return (chart_title)
}


##############################################################################
########Competitive Index Size and Colour Diagnostics chart
##############################################################################

create_compindex_chart_diagnostics <- function(input_df, chart_title, chart_caption, limit,
                                               x_axis, y_axis, size_axis, colour_axis)
{

  axis_major_unit = ceiling(limit/10/100)*100


  if(nrow(input_df)<= 20) {
    label_percentile = 1
  } else if (nrow(input_df)<= 40){
    label_percentile = 0.5
  } else label_percentile = 30/nrow(input_df)

  label_threshold_upper = quantile(input_df[["CompetitiveIndex_Current"]], 1- label_percentile, names = FALSE)
  label_threshold_lower = quantile(input_df[["CompetitiveIndex_Current"]], label_percentile, names = FALSE)
  input_df[["label_col_filter"]] = ifelse(input_df[["CompetitiveIndex_Current"]] >= label_threshold_upper | input_df[["CompetitiveIndex_Current"]] <= label_threshold_lower,
                                          input_df[["QuoteNumberTrunc"]], c(""))

  chart <- input_df %>%
    ggplot() +
    labs(title=chart_title,
         y="Chubb Proposed Premium",
         x="Ave. Competitor Premium",
         size = size_axis,
         color = colour_axis,
         caption=chart_caption
    )+
    scale_x_continuous(breaks = seq(0, limit, by = axis_major_unit), limits = c(0, limit)) +
    scale_y_continuous(breaks = seq(0, limit, by= axis_major_unit), limits = c(0, limit)) +
    scale_size_continuous(range = c(1, 5)) +
    geom_abline(col="#293D4B")+
    theme_minimal()+
    geom_point(aes(x=input_df[[x_axis]],
                   y=input_df[[y_axis]],
                   size=input_df[[size_axis]],
                   color = input_df[[colour_axis]]
    ))+
    geom_text_repel(aes(x = input_df[[x_axis]], y = input_df[[y_axis]], label=input_df[["label_col_filter"]]),
                    size = 2, color = "#293D4B")

}


create_compindex_chart_diagnostics_rainbow <- function(input_df, chart_title, chart_caption, limit,
                                                       x_axis, y_axis, size_axis, colour_axis)
{

  axis_major_unit = ceiling(limit/10/100)*100


  if(nrow(input_df)<= 20) {
    label_percentile = 1
  } else if (nrow(input_df)<= 40){
    label_percentile = 0.5
  } else label_percentile = 30/nrow(input_df)

  label_threshold_upper = quantile(input_df[["CompetitiveIndex_Current"]], 1- label_percentile, names = FALSE)
  label_threshold_lower = quantile(input_df[["CompetitiveIndex_Current"]], label_percentile, names = FALSE)
  input_df[["label_col_filter"]] = ifelse(input_df[["CompetitiveIndex_Current"]] >= label_threshold_upper | input_df[["CompetitiveIndex_Current"]] <= label_threshold_lower,
                                          input_df[["QuoteNumberTrunc"]], c(""))

  chart <- input_df %>%
    ggplot() +
    labs(title=chart_title,
         y="Chubb Proposed Premium",
         x="Ave. Competitor Premium",
         size = size_axis,
         color = colour_axis,
         caption=chart_caption
    )+
    scale_x_continuous(breaks = seq(0, limit, by = axis_major_unit), limits = c(0, limit)) +
    scale_y_continuous(breaks = seq(0, limit, by= axis_major_unit), limits = c(0, limit)) +
    scale_size_continuous(range = c(1, 5)) +
    geom_abline(col="#293D4B")+
    theme_minimal()+
    geom_point(aes(x=input_df[[x_axis]],
                   y=input_df[[y_axis]],
                   size=input_df[[size_axis]],
                   color = input_df[[colour_axis]]
    ))+
    scale_color_gradientn(colours = rainbow(5)) +
    geom_text_repel(aes(x = input_df[[x_axis]], y = input_df[[y_axis]], label=input_df[["label_col_filter"]]),
                    size = 2, color = "#293D4B")

}


##############################################################################
########generic_compare_shape_chart
##############################################################################


create_generic_compare_shape_chart <- #to do: retire this
  function(input_df, chart_title, chart_caption,
           x_axis, x_limit,
           y_axis_title, y_limit,
           y_axis_curr, y_axis_proposed,
           curr_shape_axis, proposed_shape_axis)
  {

    x_axis_major_unit = ceiling(x_limit/10/100)*100
    y_axis_major_unit = ceiling(y_limit/10/0.1)*0.1


    chart_output <-input_df %>%
      ggplot() +
      labs(title=chart_title,
           y=y_axis_title,
           x=x_axis,
           caption=chart_caption)+
      scale_x_continuous(breaks = seq(0, x_limit, by = x_axis_major_unit), limits = c(0, x_limit)) +
      scale_y_continuous(breaks = seq(0, y_limit, by= y_axis_major_unit), limits = c(0, y_limit)) +
      theme_minimal()+
      theme (axis.text.x = element_text(angle = 90)) +
      geom_point(aes(x=input_df[[x_axis]],
                     y=input_df[[y_axis_curr]],
                     colour = "Current"), size=2) +
      geom_point(aes(x=input_df[[x_axis]],
                     y=input_df[[y_axis_proposed]],
                     colour = "Proposed"), size=2) +
      scale_colour_manual("",
                          breaks = c("Current", "Proposed"),
                          values = c("#A38A00", "#1561AD"))



  }


create_generic_compare_shape_chart2 <-
  function(input_df, chart_title, chart_caption,
           x_axis, x_limit,
           y_axis_title, y_limit,
           y_axis_curr, y_axis_proposed,
           curr_shape_axis, proposed_shape_axis,
           size_axis_title, curr_size_axis, proposed_size_axis,
           label_col)
  {

    x_axis_major_unit = ceiling(x_limit/20/100)*100
    y_axis_major_unit = ceiling(y_limit/20/0.1)*0.1

    if(nrow(input_df)<= 20) {
      label_percentile = 1
    } else if (nrow(input_df)<= 40){
      label_percentile = 0.5
    } else label_percentile = 30/nrow(input_df)

    label_threshold_upper = quantile(input_df[[y_axis_proposed]], 1- label_percentile, names = FALSE)
    label_threshold_lower = quantile(input_df[[y_axis_proposed]], label_percentile, names = FALSE)

    input_df[[label_col]] <- ifelse(input_df[[y_axis_proposed]] >= label_threshold_upper | input_df[[y_axis_proposed]] <= label_threshold_lower,
                                    input_df[[label_col]], c(""))

    chart_output <-input_df %>%
      ggplot() +
      labs(title=chart_title,
           y=y_axis_title,
           x=x_axis,
           size = size_axis_title,
           caption=chart_caption)+
      scale_x_continuous(breaks = seq(0, x_limit, by = x_axis_major_unit), limits = c(0, x_limit)) +
      scale_y_continuous(breaks = seq(0, y_limit, by= y_axis_major_unit), limits = c(0, y_limit)) +
      scale_size_continuous(range = c(1, 5)) +
      theme_minimal()+
      theme (axis.text.x = element_text(angle = 90)) +
      geom_point(aes(x=input_df[[x_axis]],
                     y=input_df[[y_axis_curr]],
                     colour = "Current",
                     size=input_df[[curr_size_axis]])) +
      geom_point(aes(x=input_df[[x_axis]],
                     y=input_df[[y_axis_proposed]],
                     colour = "Proposed",
                     size=input_df[[proposed_size_axis]])) +
      geom_point(aes(x=input_df[[x_axis]],
                     y=input_df[["CI_theoretical"]],
                     colour = "Theoretical",
                     size=input_df[[proposed_size_axis]])) +
      scale_colour_manual("",
                          breaks = c("Current", "Proposed", "Theoretical"),
                          values = c("#A38A00", "#1561AD", "#BDD7EE")) +
      geom_text_repel(aes(x = input_df[[x_axis]], y = input_df[[y_axis_proposed]], label=input_df[[label_col]]),
                      size = 2, color = "#293D4B") +
      geom_hline(yintercept=1, color = "#F88379") +
      geom_hline(yintercept=0.6, color = "#F88379")
  }


##############################################################################
########compile rates table
##############################################################################


compile_rates_table <- function(input_df, class_col, target_class, category_label)
{

  output_df <- input_df %>%
    filter (input_df[[class_col]] == target_class) %>%
    select (-c(class_col))
  output_df <- output_df %>%
    gather(key = "Item", value = "value_to_be_renamed") %>%
    rename_(.dots=setNames("value_to_be_renamed", category_label))

  return (output_df)

}


compile_rates_table_multiclass <- function(input_df, class_col, target_class, category_label, gathered_col)
{
  output_df <- input_df %>%
    filter (input_df[[class_col]] %in% c(target_class))
  output_df <- output_df %>%
    #gather(key = "Item", value = "value_to_be_renamed", 2:8) %>%
    gather_(key = "Item", value = "value_to_be_renamed", colnames(input_df)[gathered_col]) %>%
    rename_(.dots=setNames("value_to_be_renamed", category_label))
  output_df[["Item"]] <- paste0(output_df[[class_col]], "-", output_df[["Item"]])
  output_df <- output_df %>%
    select (-c(class_col)) %>%
    arrange (output_df[["Item"]])
}

#print ("Initialise stage completed")





##############################################################################
########Table under CI main chart
##############################################################################


createCIChartTable <- function (section_mix, subsectionname, subsectpremcurr_colname ) #used for excel rater printer o
{

  #competitive index
  CurrentBizPackPremium_MeanTruncate <<- mean_truncate(policy_subset$CurrentBizPackPremium,0.1,0.9)
  AvgCompetitorQuote_MeanTruncate <<- mean_truncate(policy_subset$AvgCompetitorQuote,0.1,0.9)
  RecalcBizPackPremium_MeanTruncate <<- mean_truncate(policy_subset$RecalcBizPackPremium,0.1,0.9)
  CompetitiveIndex_Orig_truncate <<- CurrentBizPackPremium_MeanTruncate/AvgCompetitorQuote_MeanTruncate
  CompetitiveIndex_Proposed_truncate <<- RecalcBizPackPremium_MeanTruncate/AvgCompetitorQuote_MeanTruncate
  CompetitiveIndex_Orig_all <<- mean(policy_subset$CurrentBizPackPremium,na.rm = TRUE)/mean(policy_subset$AvgCompetitorQuote,na.rm = TRUE)
  CompetitiveIndex_Proposed_all <<- mean(policy_subset$RecalcBizPackPremium,na.rm = TRUE)/mean(policy_subset$AvgCompetitorQuote,na.rm = TRUE)

  #competitive index weighted by section mix
  CI_cur_all_mixed <<- crossprod(policy_subset$CompetitiveIndex_Current, policy_subset[[section_mix]])/sum(policy_subset[[section_mix]])
  CI_new_all_mixed <<- crossprod(policy_subset$CompetitiveIndex_Proposed, policy_subset[[section_mix]])/sum(policy_subset[[section_mix]])

  #calculate average price
  Ave_Price_Bound_Orig <<- mean(policy_subset$CurrentBizPackPremium[which(policy_subset$QuoteOutcome=="Bound")])
  Ave_Price_Bound_Proposed <<- mean(policy_subset$RecalcBizPackPremium[which(policy_subset$QuoteOutcome=="Bound")])
  Percent_Increase <<- Ave_Price_Bound_Proposed/Ave_Price_Bound_Orig-1

  Ave_Price_Quote_Orig <<- mean(policy_subset$CurrentBizPackPremium)
  Ave_Price_Quote_Proposed <<- mean(policy_subset$RecalcBizPackPremium)
  Percent_Increase_Quote <<- Ave_Price_Quote_Proposed/Ave_Price_Quote_Orig-1


  AvePriceQuoteCur <<- mean(policy_subset[[subsectpremcurr_colname]])
  AvePriceQuoteNew <<- mean(policy_subset$Recalc_sub_premium)
  Percent_Increase_Quote_sub <<- AvePriceQuoteNew/AvePriceQuoteCur-1

  num_quotes <<- nrow(policy_subset)

  #create table of results
  table_results <<- matrix(c(format(num_quotes, digits=0, nsmall=2),"","",
                             sprintf("%.0f%%", 100*CompetitiveIndex_Orig_all),sprintf("%.0f%%", 100*CompetitiveIndex_Proposed_all),"",
                             sprintf("%.0f%%", 100*CompetitiveIndex_Orig_truncate),sprintf("%.0f%%", 100*CompetitiveIndex_Proposed_truncate),"",
                             sprintf("%.0f%%", 100*CI_cur_all_mixed),sprintf("%.0f%%", 100*CI_new_all_mixed),"",
                             format(Ave_Price_Bound_Orig, digits=0, nsmall=0),format(Ave_Price_Bound_Proposed, digits=0, nsmall=0),sprintf("%.0f%%",100*Percent_Increase),
                             format(Ave_Price_Quote_Orig, digits=0, nsmall=0),format(Ave_Price_Quote_Proposed, digits=0, nsmall=0),sprintf("%.0f%%",100*Percent_Increase_Quote),
                             format(AvePriceQuoteCur, digits=0, nsmall=0),format(AvePriceQuoteNew, digits=0, nsmall=0),sprintf("%.0f%%",100*Percent_Increase_Quote_sub)
  ),
  ncol=3,byrow=TRUE)
  colnames(table_results) <<- c("Original","Proposed","% Increase")
  rownames(table_results) <<- c("# Quotes",
                                "Comp. Index: All quotes",
                                "Comp. Index: Ex. Outliers*",
                                "Comp. Index: All (Weighted by premium mix)**",
                                "Ave. price BizPack: Bound policies",
                                "Ave. price BizPack: Quoted policies",
                                paste0("Ave. price ", subsectionname, ": Quoted policies"))
  table_results <<- as.table(table_results)

  table_results2 <<- ggtexttable(table_results, theme = ttheme("lBlackWhite"))

  #text under table
  text_under_table <<- paste("*: Competitive index defined as Chubb quote/Average competitor quote. Excludes 10% lowest and highest quotes.")
  text_under_table <<- ggparagraph(text = text_under_table , face = "italic", size = 11, color = "Black")

}

#new version of createCIChartTable
createCIPage_table <- function (inputdf,
                                field_prem_Tot_curr,
                                field_prem_Tot_prop,
                                field_prem_Tot_market,
                                #section_mix,
                                subsectionname,
                                field_prem_Sub_curr,
                                field_prem_Sub_prop)
{

  #competitive index
  CurrentBizPackPremium_MeanTruncate <<- mean_truncate(inputdf[[field_prem_Tot_curr]],0.1,0.9)
  AvgCompetitorQuote_MeanTruncate <<- mean_truncate(inputdf[[field_prem_Tot_market]],0.1,0.9)
  RecalcBizPackPremium_MeanTruncate <<- mean_truncate(inputdf[[field_prem_Tot_prop]],0.1,0.9)
  CompetitiveIndex_Orig_truncate <<- CurrentBizPackPremium_MeanTruncate/AvgCompetitorQuote_MeanTruncate
  CompetitiveIndex_Proposed_truncate <<- RecalcBizPackPremium_MeanTruncate/AvgCompetitorQuote_MeanTruncate
  CompetitiveIndex_Orig_all <<- mean(inputdf[[field_prem_Tot_curr]],na.rm = TRUE)/mean(inputdf[[field_prem_Tot_market]],na.rm = TRUE)
  CompetitiveIndex_Proposed_all <<- mean(inputdf[[field_prem_Tot_prop]],na.rm = TRUE)/mean(inputdf[[field_prem_Tot_market]],na.rm = TRUE)

  #competitive index weighted by section mix
  # CI_cur_all_mixed <<- crossprod(inputdf$CompetitiveIndex_Current, inputdf[[section_mix]])/sum(inputdf[[section_mix]])
  # CI_new_all_mixed <<- crossprod(inputdf$CompetitiveIndex_Proposed, inputdf[[section_mix]])/sum(inputdf[[section_mix]])

  #calculate average price
  Ave_Price_Bound_Orig <<- mean(inputdf[[field_prem_Tot_curr]][which(inputdf[["QuoteOutcome"]]=="Bound")])
  Ave_Price_Bound_Proposed <<- mean(inputdf[[field_prem_Tot_prop]][which(inputdf[["QuoteOutcome"]]=="Bound")])
  Percent_Increase <<- Ave_Price_Bound_Proposed/Ave_Price_Bound_Orig-1

  Ave_Price_Quote_Orig <<- mean(inputdf[[field_prem_Tot_curr]])
  Ave_Price_Quote_Proposed <<- mean(inputdf[[field_prem_Tot_prop]])
  Percent_Increase_Quote <<- Ave_Price_Quote_Proposed/Ave_Price_Quote_Orig-1


  AvePriceQuoteCur <<- mean(inputdf[[field_prem_Sub_curr]])
  AvePriceQuoteNew <<- mean(inputdf[[field_prem_Sub_prop]])
  Percent_Increase_Quote_sub <<- AvePriceQuoteNew/AvePriceQuoteCur-1

  num_quotes <<- nrow(inputdf)

  #create table of results
  table_results <<- matrix(c(format(num_quotes, digits=0, nsmall=2),"","",
                             sprintf("%.0f%%", 100*CompetitiveIndex_Orig_all),sprintf("%.0f%%", 100*CompetitiveIndex_Proposed_all),"",
                             sprintf("%.0f%%", 100*CompetitiveIndex_Orig_truncate),sprintf("%.0f%%", 100*CompetitiveIndex_Proposed_truncate),"",
                             #sprintf("%.0f%%", 100*CI_cur_all_mixed),sprintf("%.0f%%", 100*CI_new_all_mixed),"",
                             format(Ave_Price_Bound_Orig, digits=0, nsmall=0),format(Ave_Price_Bound_Proposed, digits=0, nsmall=0),sprintf("%.0f%%",100*Percent_Increase),
                             format(Ave_Price_Quote_Orig, digits=0, nsmall=0),format(Ave_Price_Quote_Proposed, digits=0, nsmall=0),sprintf("%.0f%%",100*Percent_Increase_Quote),
                             format(AvePriceQuoteCur, digits=0, nsmall=0),format(AvePriceQuoteNew, digits=0, nsmall=0),sprintf("%.0f%%",100*Percent_Increase_Quote_sub)
  ),
  ncol=3,byrow=TRUE)
  colnames(table_results) <<- c("Original","Proposed","% Increase")
  rownames(table_results) <<- c("# Quotes",
                                "Comp. Index: All quotes",
                                "Comp. Index: Ex. Outliers*",
                                #"Comp. Index: All (Weighted by premium mix)**",
                                "Ave. price BizPack: Bound policies",
                                "Ave. price BizPack: Quoted policies",
                                paste0("Ave. price ", subsectionname, ": Quoted policies"))
  table_results <<- as.table(table_results)

  table_results2 <<- ggtexttable(table_results, theme = ttheme("lBlackWhite"))

  #text under table
  text_under_table <<- paste("*: Competitive index defined as Chubb quote/Average competitor quote. Excludes 10% lowest and highest quotes.")
  text_under_table <<- ggparagraph(text = text_under_table , face = "italic", size = 11, color = "Black")

  cat ("table_results2 and text_under_table created \n")
}




create_CImonitoring_maptable <- function (input_df)
{

  table_output <- input_df %>%
    ungroup() %>%
    select (IndGroupedShort,
            IndGrouped_count,
            NAIC6D,
            PreferredAtNAIC6D,
            NAIC6D_count,
            IndustryCode_Internal,
            IndustryDesc_Internal,
            PreferredAtBrokerCode,
            IndustryDesc_Internal_count) %>%
    rename(Grp = IndGroupedShort,
           GrpCount = IndGrouped_count,
           N6D = NAIC6D,
           PrefN6D = PreferredAtNAIC6D,
           N6DCount = NAIC6D_count,
           ChubbC = IndustryCode_Internal,
           ChubbDesc = IndustryDesc_Internal,
           PrefCCode = PreferredAtBrokerCode,
           ChubbCCount = IndustryDesc_Internal_count
    )

  return(table_output)
}








createCIChartTable_monitoring <- function (input_df)
{
  #number of quotes and strike rate
  num_quotes <<- nrow(input_df)
  num_quotes_bound <<- nrow(input_df %>% filter (boundflag == "Bound"))
  strike_rate = num_quotes_bound/num_quotes

  #competitive index
  CurrentBizPackPremium_MeanTruncate <<- mean_truncate(input_df$Your.Average.Base.Premium,0.1,0.9)
  AvgCompetitorQuote_MeanTruncate <<- mean_truncate(input_df$AvgCompetitorQuote,0.1,0.9)
  CompetitiveIndex_Orig_truncate <<- CurrentBizPackPremium_MeanTruncate/AvgCompetitorQuote_MeanTruncate
  CompetitiveIndex_Orig_all <<- mean(input_df$Your.Average.Base.Premium,na.rm = TRUE)/mean(input_df$AvgCompetitorQuote,na.rm = TRUE)

  #calculate average price
  Ave_Price_Bound_Orig <<- mean(input_df$Your.Average.Base.Premium[which(input_df$QuoteOutcome=="Bound")])
  Ave_Price_Quote_Orig <<- mean(input_df$Your.Average.Base.Premium)

  #create table of results
  table_results <<- matrix(c(format(num_quotes, digits=0, nsmall=2),
                             sprintf("%.1f%%", 100*strike_rate),
                             sprintf("%.0f%%", 100*CompetitiveIndex_Orig_all),
                             sprintf("%.0f%%", 100*CompetitiveIndex_Orig_truncate),
                             format(Ave_Price_Bound_Orig, digits=0, nsmall=0),
                             format(Ave_Price_Quote_Orig, digits=0, nsmall=0)
  ), ncol=1, byrow=TRUE)

  colnames(table_results) <<- c("Current")
  rownames(table_results) <<- c("# Quotes",
                                "Strike rate",
                                "Comp. Index: All quotes",
                                "Comp. Index: Ex. Outliers*",
                                "Ave. price BizPack: Bound policies",
                                "Ave. price BizPack: Quoted policies"
  )

  table_results <<- as.table(table_results)

  table_results2 <<- ggtexttable(table_results, theme = ttheme("lBlackWhite"))

  #text under table
  text_under_table <<- paste("*: Competitive index defined as Chubb quote/Average competitor quote. Excludes 10% lowest and highest quotes.")
  text_under_table <<- ggparagraph(text = text_under_table , face = "italic", size = 11, color = "Black")

}



##############################################################################
########Table of policies row count
##############################################################################

createpolicytable_rowcount <- function (input_df)
{

  row_count <<- nrow(input_df)

  if(row_count >= 45)
  {
    row_middle <<- round(row_count/2,0)
    row_increment <<- 15
  }
  else
  {
    row_increment <<- floor (row_count/3)
    row_middle <<- row_increment +1
  }

}

#print ("Initialise complete")



##############################################################################
########Rates table page
##############################################################################


create_rates_table_page <- function (title, input_df)
{

  temp_text <- paste("NAIC2D: ", title, "Change in rates. Current rates are sourced from the April 2020 Production Tables",
                     "Minimum premium is before commissions")
  temp_text <- ggparagraph(text = temp_text , size = 11, color = "Black")


  if (nrow(input_df)> 60){
    input_df2a <- input_df  %>% slice(1:60)
    input_df2b <- input_df  %>% slice(61:nrow(input_df))
  }else{
    input_df2a <- input_df
    input_df2b <- c("")}


  input_df2a <- ggtexttable(input_df2a,
                            theme = ttheme
                            (
                              colnames.style = colnames_style(size = 8),
                              tbody.style = tbody_style(color = "black", size = 8),
                              padding = unit(c(1, 1),"mm")
                            ))

  input_df2b <- ggtexttable(input_df2b,
                            theme = ttheme
                            (
                              colnames.style = colnames_style(size = 8),
                              tbody.style = tbody_style(color = "black", size = 8),
                              padding = unit(c(1, 1),"mm")
                            ))

  output <- ggarrange(input_df2a,input_df2b,temp_text, ncol = 3, nrow = 1
  )
}

#print ("Initialisation complete")



##############################################################################
########Pricing calculators
##############################################################################

CreateGeneralisedFieldnames <- function (subsectionname)
  {

  BI_SI_generalised <<- paste0("BI_SI_",subsectionname)

  SSMultiplier_generalised.Selected <<- paste0("SSMultiplier_",subsectionname)
  # SSF1_generalised.Selected <<- paste0("SSF1_",subsectionname,".Selected")
  SSBase_generalised.Selected <<- paste0("SSBase_",subsectionname,".Selected")
  SSF2_generalised.Selected <<- paste0("SSF2_",subsectionname,".Selected")
  SSF1_generalised.Selected <<- paste0("SSF1_",subsectionname,".Selected")
  Prm_Sub2_BI_generalised_Selected <<- paste0("Prm_Sub2_BI_",subsectionname,".Selected")
  Base_generalised.Selected <<- paste0("Base_",subsectionname,".Selected")
  ModIndem_generalised.Selected <<- paste0("ModIndem_",subsectionname,".Selected")

  Prm_Sub2_BI_generalised <<- paste0("Prm_Sub2_BI_",subsectionname)

}

#rename this, this is to generalise both modifier and premium col names
Create_ModColName <- function (ModName, sectionname, postfix)
{
  temp <- paste0(sectionname,"_",ModName,"_", postfix)
  return (temp)
}

Create_PricingColName <- function (ColName, sectionname, postfix)
{

  ColName = as.list(ColName)


  temp <- paste0(sectionname,"_",ColName,"_", postfix)
  return (temp)
}



PriceCalc_BI <- function (df, subsectionname)
{
  #prepare generalised fieldnames
  # SSMultiplier_generalised = paste0("SSMultiplier_",subsectionname)
  # SSF1_generalised.Selected = paste0("SSF1_",subsectionname,".Selected")
  # BI_SI_generalised = paste0("BI_SI_",subsectionname)
  # SSBase_generalised.Selected = paste0("SSBase_",subsectionname,".Selected")
  # SSF2_generalised.Selected = paste0("SSF2_",subsectionname,".Selected")
  # SSF1_generalised.Selected = paste0("SSF1_",subsectionname,".Selected")
  # Prm_Sub2_BI_generalised_Selected = paste0("Prm_Sub2_BI_",subsectionname,".Selected")
  # Base_generalised.Selected = paste0("Base_",subsectionname,".Selected")
  # ModIndem_generalised = paste0("ModIndem_",subsectionname)

  CreateGeneralisedFieldnames (subsectionname)

  df[[SSMultiplier_generalised.Selected]] = df[[SSF1_generalised.Selected]] * pmax(df[[BI_SI_generalised]],df[[SSBase_generalised.Selected]]) ^ (df[[SSF2_generalised.Selected]])
  # df[[SSMultiplier_generalised.Selected]] = pmax(df[[BI_SI_generalised]],df[[SSBase_generalised.Selected]])
  df[[Prm_Sub2_BI_generalised_Selected]] = df[[BI_SI_generalised]] *
    df[[SSMultiplier_generalised.Selected]] *
    df[["FireRate"]] *
    df[[Base_generalised.Selected]] *
    df[[ModIndem_generalised.Selected]]
  return (df)

}

PriceCalc_BI_formatnumbers <- function (df, subsectionname)
{
  CreateGeneralisedFieldnames (subsectionname)

  # 0 dp
  df[[BI_SI_generalised]]= sprintf("%.0f", df[[BI_SI_generalised]])
  df[[SSBase_generalised.Selected]]= sprintf("%.0f", df[[SSBase_generalised.Selected]])
  df[[Prm_Sub2_BI_generalised_Selected]]= sprintf("%.0f", df[[Prm_Sub2_BI_generalised_Selected]])
  df[[Prm_Sub2_BI_generalised]]= sprintf("%.0f", df[[Prm_Sub2_BI_generalised]])


  # 2 dp
  df[[SSF1_generalised.Selected]]= sprintf("%.2f", df[[SSF1_generalised.Selected]])
  df[[Base_generalised.Selected]]= sprintf("%.2f", df[[Base_generalised.Selected]])
  df[[ModIndem_generalised.Selected]]= sprintf("%.2f", df[[ModIndem_generalised.Selected]])

  # 3 dp
  df[[SSMultiplier_generalised.Selected]]= sprintf("%.3f", df[[SSMultiplier_generalised.Selected]])
  df[[SSF2_generalised.Selected]]= sprintf("%.3f", df[[SSF2_generalised.Selected]])



  return (df)

}

format_processedquotedata_allsections <- function (df)
{
  # 0 dp
  df[["ModifiedPremium"]]= sprintf("%.0f", df[["ModifiedPremium"]])
  df[["Your.Average.Base.Premium"]]= sprintf("%.0f", df[["Your.Average.Base.Premium"]])
  df[["AvgCompetitorQuote"]]= sprintf("%.0f", df[["AvgCompetitorQuote"]])

  return (df)
}

format_processedquotedata_BI <- function (df)
{
  # 0 dp
  df[["Prm_Sub_BI_Tot"]]= sprintf("%.0f", df[["Prm_Sub_BI_Tot"]])

  # % 1 dp
  df[["PremMixBI"]]= sprintf("%.1f%%", 100*df[["PremMixBI"]])

  # % 4 dp
  df[["FireRate"]]= sprintf("%.4f%%", 100*df[["FireRate"]])

  return (df)
}


#cat ("\n Initialise complete")




###########################################################################################
#######Columnname master list
###########################################################################################

fieldlist_occupation_short = c("NAIC6DToRate",
                               "NAIC6DDesc_ToRate",
                               "IndGroupedShort_ToRate",
                               "IndustryCode_Internal",
                               "IndustryDesc_Internal",
                               "PreferredAtNAIC6D_ToRate",
                               "PreferredAtBrokerCode")


fieldlist_occupation = c(fieldlist_occupation_short,
                         "NAIC6D",
                         "NAIC5D",
                         "NAIC4D",
                         "NAIC3D",
                         "NAIC2D",
                         "NAIC6DDesc",
                         "NAIC5DDesc",
                         "NAIC4DDesc",
                         "NAIC3DDesc",
                         "NAIC2DDesc",
                         "NAIC2DDescShort",
                         "IndGrouped")

fieldlist_occupation_tenant = c("Tenant_NAIC6D",
                                "Tenant_NAIC5D",
                                "Tenant_NAIC4D",
                                "Tenant_NAIC3D",
                                "Tenant_NAIC2D",
                                "Tenant_NAIC6DDesc",
                                "Tenant_NAIC5DDesc",
                                "Tenant_NAIC4DDesc",
                                "Tenant_NAIC3DDesc",
                                "Tenant_NAIC2DDescShort",
                                "Tenant_IndGroupedShort",
                                "Tenant_PreferredAtNAIC6D"
                                #"POCCode_TenantN6D"
)

fieldlist_reviewtracker = c("RevVer_LiabAll_ToRate",
                            "RevVer_FireAll_ToRate",
                            "RevVer_All_ToRate",
                            "ReviewNotes_N6D_ToRate"
)

fieldlist_reviewtracker_tenant = c("")#,ReviewFlag_N6D_Tenant")

fieldlist_quoteinfo_short = c("QuoteNumber",
                              "ProposalID",
                              "Opp_YrMth",
                              "Opportunity.Presented.Date",
                              "QuoteOutcome",
                              "boundflag",
                              "AvgCompetitorQuote",
                              "Your.Average.Base.Premium",
                              "ModifiedPremium")

# fieldlist_premiums_fire = c()



#fieldlist_quoteinfo = c(fieldlist_quoteinfo_short,
 #                       "Inception_YrMth",
  #                      "Location_LocationProposalID",
   #                     "Location_Count_Flag",
    #                    "EntsiaPremReconcile",
     #                   "Category",
      #                  "ZeroPremFlag")




#fieldlist_nonratingfactors = c(
 # fieldlist_occupation,
  #fieldlist_occupation_tenant,
  #fieldlist_reviewtracker,
  #fieldlist_reviewtracker_tenant,
  #fieldlist_quoteinfo)



############Premiums

#fieldlist_systempremiums_Fire_L1 = c("Prm_Sub_Fire_Tot",
 #                                    "Prm_Sub2_Fire_BTot",
  #                                   "Prm_Sub2_Fire_BTot_exFld",
   #                                  "Prm_Sub2_Fire_CTot",
    #                                 "Prm_Sub2_Fire_CTot_exFld")

#fieldlist_systempremiums_Fire_L1_Select = c("Prm_Sub_Fire_Tot_Select",
 #                                           "Prm_Sub2_Fire_BTot_Select",
  #                                          "Prm_Sub2_Fire_BTot_exFld_Select",
   #                                         "Prm_Sub2_Fire_CTot_Select",
    #                                        "Prm_Sub2_Fire_CTot_exFld_Select",
     #                                       "ModifiedPremium_Select")






#fieldlist_systempremiums_Fire = c(fieldlist_systempremiums_L1,
 #                                 "Prm_Sub2_Fire_BBush",
  #                                "Prm_Sub2_Fire_BCyc",
   #                               "Prm_Sub2_Fire_BEqt",
    #                              "Prm_Sub2_Fire_BFld",
     #                             "Prm_Sub2_Fire_BHail",
      #                            "Prm_Sub2_Fire_BRsk",
       #                           "Prm_Sub2_Fire_BStm",

        #                          "Prm_Sub2_Fire_CBush",
         #                         "Prm_Sub2_Fire_CCyc",
          #                        "Prm_Sub2_Fire_CEqt",
           #                       "Prm_Sub2_Fire_CFld",
            #                      "Prm_Sub2_Fire_CHail",
             #                     "Prm_Sub2_Fire_CRsk",
              #                    "Prm_Sub2_Fire_CStm",
               #                   fieldlist_premmix)






#ColList_premiums_L0 = c("Prm_Tot_POLICY")
#ColList_premiums_L1 = c("Prm_Sub_Fire_Tot",
 #                       "Prm_Sub2_Fire_BTot",
  #                      "Prm_Sub2_Fire_CTot",
   #                     "Prm_Sub_BI_Tot",
    #                    "Prm_Sub_Liab_Tot",
     #                   "Prm_Sub_Electric_Tot",
      #                  "Prm_Sub_Fidel_Tot",
       #                 "Prm_Sub_GProp_Tot",
        #                "Prm_Sub_Gls_Tot",
         #               "Prm_Sub_Mach_Tot",
          #              "Prm_Sub_Money_Tot",
           #             "Prm_Sub_Tax_Tot",
            #            "Prm_Sub_Theft_Tot")



###########################################################################################
#######Premium Mix
###########################################################################################


create_L1_PremMix <- function (input_df, numerator_cols, denominator_col){

  for (i in numerator_cols) {

    temp_mix_colname = paste0(i,"_Mix")

    input_df <- input_df %>%
      mutate(
        #temp = !!sym(i)/!!sym(denominator_col))
        temp = !!sym(i)/!!sym(denominator_col)) %>%
      rename (!!temp_mix_colname := temp)
    #input_df[[temp]] = input_df[[i]]/input_df[[denominator_col]]

  }
  return (input_df)
}



