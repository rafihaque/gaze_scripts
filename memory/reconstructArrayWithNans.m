function fullArray = reconstructArrayWithNans(isVal,Array)
	fullArray=nan(length(isVal),1);
	fullArray(find(isVal))=Array;
end
