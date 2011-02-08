function h5datasets, file

datasets = ''
res = H5_PARSE(file)
tags = TAG_NAMES(res)
for i=0,N_ELEMENTS(tags)-1 do begin
   IF( strmid(tags[i],0,1) NE '_') then begin
      ok = Execute('type = res.'+tags[i]+'._TYPE')
      if(type EQ 'DATASET') then begin
         ok = Execute('datasets = [datasets,"'+strlowcase(tags(i))+'"]')
      endif
   endif
endfor

return, datasets
end