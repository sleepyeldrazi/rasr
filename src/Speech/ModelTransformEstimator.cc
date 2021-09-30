/** Copyright 2020 RWTH Aachen University. All rights reserved.
 *
 *  Licensed under the RWTH ASR License (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.hltpr.rwth-aachen.de/rwth-asr/rwth-asr-license.html
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
#include "ModelTransformEstimator.hh"
#include <Am/ClassicAcousticModel.hh>
#include <Core/Directory.hh>
#include <Core/MapParser.hh>
#include <Mm/MixtureSet.hh>
#if defined(MODULE_ADAPT_ADVANCED) && !defined(__ANDROID__)
#include <Mm/BandMllrAdaptation.hh>
#include <Mm/SemiTiedAdaptation.hh>
#endif

using namespace Speech;

const Core::Choice ModelTransformEstimator::mllrModelingChoice(
        "full", fullMllr,
        "semi-tied", semiTiedMllr,
        "band", bandMllr,
        "shift", shiftMllr,
        Core::Choice::endMark());
const Core::ParameterChoice ModelTransformEstimator::paramMllrModeling(
        "mllr-modeling", &mllrModelingChoice,
        "structure of MLLR modeling (full, semi-tied, band, shift)[full]",
        fullMllr);

ModelTransformEstimator::ModelTransformEstimator(const Core::Configuration& c, Operation o)
        : Component(c),
          Precursor(c, o) {
    mllrModeling_   = MllrModelingMode(paramMllrModeling(config));
    adaptationTree_ = Core::ref(new Am::AdaptationTree(select("mllr-tree"),
                                                       (dynamic_cast<const Am::ClassicAcousticModel&>(*acousticModel())).stateModel(),
                                                       acousticModel()->silence()));

    Core::IoRef<Mm::AbstractAdaptationAccumulator>::registerClass<Mm::FullAdaptorViterbiEstimator>(config, adaptationTree_);
    Core::IoRef<Mm::AbstractAdaptationAccumulator>::registerClass<Mm::ShiftAdaptorViterbiEstimator>(config, adaptationTree_);
#ifdef MODULE_ADAPT_ADVANCED
    Core::IoRef<Mm::AbstractAdaptationAccumulator>::registerClass<Mm::BandMllrEstimator>(config, adaptationTree_);
    Core::IoRef<Mm::AbstractAdaptationAccumulator>::registerClass<Mm::SemiTiedEstimator>(config, adaptationTree_);
#endif
}

ModelTransformEstimator::~ModelTransformEstimator() {}

void ModelTransformEstimator::createAccumulator(std::string key) {
    Core::Ref<const Mm::MixtureSet> mixtureSet = mixtureSet_;
    switch (mllrModeling_) {
        case fullMllr:
            currentAccumulator_ = new Accumulator(new Mm::FullAdaptorViterbiEstimator(config, mixtureSet, adaptationTree_));
            break;
        case shiftMllr:
            currentAccumulator_ = new Accumulator(new Mm::ShiftAdaptorViterbiEstimator(config, mixtureSet, adaptationTree_));
            break;
#ifdef MODULE_ADAPT_ADVANCED
        case semiTiedMllr:
            currentAccumulator_ = new Accumulator(new Mm::SemiTiedEstimator(config, mixtureSet, adaptationTree_));
            break;
        case bandMllr:
            currentAccumulator_ = new Accumulator(new Mm::BandMllrEstimator(config, mixtureSet, adaptationTree_));
            break;
#endif
        default:
            defect();
    }
}

void ModelTransformEstimator::postProcess() {
    AdaptorCache adaptorCache(select("adaptor-cache"), Core::createObjectCacheMode);
    if (adaptorCache.getDirectory() == "")
        return;

    std::set<std::string> seenKeys = accumulatorCache_.keys();
    log("Number of keys: %zu", seenKeys.size());

    for (std::set<std::string>::iterator key = seenKeys.begin(); key != seenKeys.end(); ++key) {
        log("Estimating adaptor for key: ") << *key;
        currentAccumulator_ = const_cast<Accumulator*>(accumulatorCache_.findForReadAccess(*key));
        verify(currentAccumulator_);

        ConcreteAccumulator* concreteCurrentAccumulator = dynamic_cast<ConcreteAccumulator*>(&**currentAccumulator_);

        adaptorCache.insert(*key, new Core::IoRef<Mm::Adaptor>(concreteCurrentAccumulator->adaptor()));
    }
}
